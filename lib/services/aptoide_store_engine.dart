import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/store_app.dart';

class AptoideStoreException implements Exception {
  final String message;
  AptoideStoreException(this.message);
  @override
  String toString() => 'AptoideStoreException: $message';
}

/// Motor leve para o Aptoide, usando a API JSON pública deles (webservice
/// v7 - o mesmo que o app oficial do Aptoide consome). Não é scraping de
/// HTML: é o endpoint JSON documentado em webservices.aptoide.com.
class AptoideStoreEngine {
  final http.Client _client;
  static const String _baseUrl = 'https://ws75.aptoide.com/api/7';
  static const String repoLabel = 'Aptoide';

  AptoideStoreEngine({http.Client? client}) : _client = client ?? http.Client();

  /// Busca apps por termo de busca (ex: categoria, nome, palavra-chave).
  /// A API do Aptoide é orientada a busca/loja, não tem um dump completo
  /// do catálogo como o index-v2.json do F-Droid.
  Future<List<StoreApp>> searchApps(String query, {int limit = 20}) async {
    final uri = Uri.parse('$_baseUrl/apps/search/query=${Uri.encodeComponent(query)}/limit=$limit');
    final json = await _getJson(uri, 'busca "$query"');

    final datalist = json['datalist'] as Map<String, dynamic>?;
    final list = datalist?['list'] as List<dynamic>?;
    if (list == null || list.isEmpty) return [];

    return list.whereType<Map<String, dynamic>>().map(_mapAppJsonToStoreApp).whereType<StoreApp>().toList();
  }

  /// Busca os metadados completos de um app específico pelo package name.
  Future<StoreApp?> getAppMeta(String packageName) async {
    final uri = Uri.parse('$_baseUrl/app/getMeta/package_name=${Uri.encodeComponent(packageName)}');
    final json = await _getJson(uri, packageName);

    final data = json['data'] as Map<String, dynamic>?;
    if (data == null) return null;

    return _mapAppJsonToStoreApp(data);
  }

  StoreApp? _mapAppJsonToStoreApp(Map<String, dynamic> data) {
    try {
      final packageName = data['package'] as String?;
      final name = data['name'] as String?;
      final icon = data['icon'] as String? ?? '';
      if (packageName == null || packageName.isEmpty || name == null) return null;

      final file = data['file'] as Map<String, dynamic>?;
      final downloadUrl = file?['path'] as String?; // link direto do .apk, sem zip
      if (downloadUrl == null || downloadUrl.isEmpty) return null;

      final versionName = file?['vername'] as String? ?? 'desconhecida';
      final versionCode = (file?['vercode'] as num?)?.toInt() ?? 0;

      final developerObj = data['developer'] as Map<String, dynamic>?;
      final developer = developerObj?['name'] as String?;

      final stats = data['stats'] as Map<String, dynamic>?;
      final downloads = (stats?['downloads'] as num?)?.toInt() ?? 0;
      final ratingObj = stats?['rating'] as Map<String, dynamic>?;
      final ratingAvg = (ratingObj?['avg'] as num?)?.toDouble();

      final sizeBytes = (data['size'] as num?)?.toInt() ?? (file?['filesize'] as num?)?.toInt() ?? 0;

      return StoreApp(
        id: packageName,
        title: name,
        version: versionName,
        versionCode: versionCode,
        iconUrl: icon,
        downloadUrl: downloadUrl,
        description: 'Sem descrição.', // apps/search e getMeta não retornam descrição longa
        source: 'aptoide',
        packageName: packageName,
        repoLabel: repoLabel,
        developer: developer,
        downloads: downloads,
        ratingAvg: ratingAvg,
        sizeBytes: sizeBytes,
      );
    } catch (_) {
      // Item malformado é ignorado, o resto da lista segue normalmente.
      return null;
    }
  }

  Future<Map<String, dynamic>> _getJson(Uri uri, String context) async {
    late http.Response response;
    try {
      response = await _client.get(uri).timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw AptoideStoreException('Timeout ao buscar "$context" no Aptoide');
    } on http.ClientException catch (e) {
      throw AptoideStoreException('Erro de rede ao buscar "$context" no Aptoide: $e');
    } catch (e) {
      throw AptoideStoreException('Erro inesperado ao buscar "$context" no Aptoide: $e');
    }

    if (response.statusCode != 200) {
      throw AptoideStoreException('HTTP ${response.statusCode} ao buscar "$context" no Aptoide');
    }

    Map<String, dynamic> json;
    try {
      json = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      throw AptoideStoreException('JSON inválido do Aptoide para "$context": $e');
    }

    final info = json['info'] as Map<String, dynamic>?;
    final status = info?['status'] as String?;
    if (status != null && status != 'OK') {
      throw AptoideStoreException('Aptoide retornou status "$status" para "$context"');
    }

    return json;
  }

  void dispose() => _client.close();
}
