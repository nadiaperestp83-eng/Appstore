import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/store_app.dart';

class CodebergStoreException implements Exception {
  final String message;
  CodebergStoreException(this.message);
  @override
  String toString() => 'CodebergStoreException: $message';
}

/// Motor leve para buscar releases (.apk) de repositórios hospedados no
/// Codeberg (instância pública do Forgejo/Gitea). A API do Gitea é
/// intencionalmente compatível com a da GitHub para releases - mesmo
/// formato de `assets` com `browser_download_url` -, então este motor é
/// praticamente um espelho de [GithubStoreEngine], só trocando a base URL.
class CodebergStoreEngine {
  final http.Client _client;
  static const String _baseUrl = 'https://codeberg.org/api/v1/repos';

  CodebergStoreEngine({http.Client? client}) : _client = client ?? http.Client();

  /// Busca a release mais recente de cada repositório em [repos]
  /// (formato "dono/repo") e agrega tudo em uma única lista de StoreApp.
  /// Falhas individuais de um repo não derrubam a busca dos demais.
  Future<List<StoreApp>> fetchLatestApps(List<String> repos) async {
    final results = await Future.wait(
      repos.map((r) async {
        try {
          return await _fetchRepoApps(r);
        } catch (e) {
          // ignore: avoid_print
          print('[CodebergStoreEngine] Falha em "$r": $e');
          return <StoreApp>[];
        }
      }),
    );
    return results.expand((apps) => apps).toList();
  }

  Future<List<StoreApp>> _fetchRepoApps(String ownerRepo) async {
    final parts = ownerRepo.split('/');
    if (parts.length != 2 || parts[0].isEmpty || parts[1].isEmpty) {
      throw CodebergStoreException('Formato inválido de repositório: "$ownerRepo". Use "dono/repo".');
    }
    final owner = parts[0];
    final repo = parts[1];

    final releasesJson = await _getJson('$_baseUrl/$owner/$repo/releases', ownerRepo);
    if (releasesJson is! List || releasesJson.isEmpty) return [];

    final latestRelease = releasesJson.firstWhere(
      (r) => r is Map && r['draft'] == false,
      orElse: () => releasesJson.first,
    ) as Map<String, dynamic>;

    final apps = _mapReleaseToApps(latestRelease, ownerRepo, repo);

    // Releases não trazem ícone: usamos o avatar do dono do repositório.
    if (apps.isNotEmpty) {
      final iconUrl = await _fetchOwnerAvatar(owner, repo, ownerRepo);
      return apps
          .map((a) => StoreApp(
                id: a.id,
                title: a.title,
                version: a.version,
                iconUrl: iconUrl,
                downloadUrl: a.downloadUrl,
                description: a.description,
                source: a.source,
              ))
          .toList();
    }
    return apps;
  }

  Future<String> _fetchOwnerAvatar(String owner, String repo, String ownerRepo) async {
    try {
      final repoInfo = await _getJson('$_baseUrl/$owner/$repo', ownerRepo);
      final ownerData = repoInfo is Map ? repoInfo['owner'] : null;
      return (ownerData is Map ? ownerData['avatar_url'] as String? : null) ?? '';
    } catch (_) {
      return '';
    }
  }

  Future<dynamic> _getJson(String url, String context) async {
    late http.Response response;
    try {
      response = await _client.get(Uri.parse(url), headers: {'Accept': 'application/json'}).timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw CodebergStoreException('Timeout ao acessar "$context"');
    } on http.ClientException catch (e) {
      throw CodebergStoreException('Erro de rede em "$context": $e');
    } catch (e) {
      throw CodebergStoreException('Erro inesperado em "$context": $e');
    }

    if (response.statusCode == 404) {
      throw CodebergStoreException('Não encontrado: "$context"');
    }
    if (response.statusCode == 403 || response.statusCode == 429) {
      throw CodebergStoreException('Rate limit do Codeberg atingido para "$context"');
    }
    if (response.statusCode != 200) {
      throw CodebergStoreException('HTTP ${response.statusCode} em "$context"');
    }

    try {
      return jsonDecode(response.body);
    } catch (e) {
      throw CodebergStoreException('JSON inválido em "$context": $e');
    }
  }

  List<StoreApp> _mapReleaseToApps(Map<String, dynamic> release, String ownerRepo, String repo) {
    final assets = (release['assets'] as List<dynamic>?) ?? [];
    final apkAssets = assets.where((a) {
      final name = (a is Map ? a['name'] as String? : null) ?? '';
      return name.toLowerCase().endsWith('.apk');
    }).toList();

    if (apkAssets.isEmpty) return [];

    final version = (release['tag_name'] as String?) ?? (release['name'] as String?) ?? 'desconhecida';
    final description = ((release['body'] as String?) ?? '').trim();

    return apkAssets.map((asset) {
      final a = asset as Map<String, dynamic>;
      final apkName = a['name'] as String? ?? repo;
      final downloadUrl = a['browser_download_url'] as String? ?? '';
      return StoreApp(
        id: '$ownerRepo::$apkName',
        title: repo,
        version: version,
        iconUrl: '',
        downloadUrl: downloadUrl, // link direto do .apk, sem zip
        description: description.isEmpty ? 'Sem descrição.' : description,
        source: 'codeberg',
        packageName: null, // desconhecido até o .apk ser baixado e o manifest lido
        repoLabel: 'Codeberg: $ownerRepo',
      );
    }).toList();
  }

  void dispose() => _client.close();
}
