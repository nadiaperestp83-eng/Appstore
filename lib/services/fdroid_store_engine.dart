import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show compute;
import 'package:http/http.dart' as http;
import '../models/store_app.dart';

class FDroidStoreException implements Exception {
  final String message;
  FDroidStoreException(this.message);
  @override
  String toString() => 'FDroidStoreException: $message';
}

/// Motor leve para consumir o index-v2.json do repositório oficial do F-Droid
/// (ou de repositórios compatíveis, como o usado pelo Droid-ify).
class FDroidStoreEngine {
  final http.Client _client;
  final String repoBaseUrl;
  final String repoLabel;

  FDroidStoreEngine({
    http.Client? client,
    this.repoBaseUrl = 'https://f-droid.org/repo', // repositório oficial
    this.repoLabel = 'F-Droid oficial',
  }) : _client = client ?? http.Client();

  String get _indexUrl => '$repoBaseUrl/index-v2.json';

  /// Baixa e processa o index-v2.json, retornando um StoreApp por pacote
  /// com a versão mais recente disponível.
  Future<List<StoreApp>> fetchApps({int? limit}) async {
    final raw = await _downloadIndex();

    List<StoreApp> apps;
    try {
      // Parsing roda em isolate separado (compute) por ser um JSON pesado.
      apps = await compute(_parseIndexV2, _ParseArgs(raw, repoBaseUrl, repoLabel));
    } catch (e) {
      throw FDroidStoreException('Erro ao processar index-v2.json: $e');
    }

    if (limit != null && limit < apps.length) {
      return apps.sublist(0, limit);
    }
    return apps;
  }

  Future<String> _downloadIndex() async {
    late http.Response response;
    try {
      response = await _client.get(Uri.parse(_indexUrl)).timeout(const Duration(seconds: 60));
    } on TimeoutException {
      throw FDroidStoreException('Timeout ao baixar $_indexUrl');
    } on http.ClientException catch (e) {
      throw FDroidStoreException('Erro de rede ao baixar index F-Droid: $e');
    } catch (e) {
      throw FDroidStoreException('Erro inesperado ao baixar index F-Droid: $e');
    }

    if (response.statusCode != 200) {
      throw FDroidStoreException('Falha ao baixar index-v2.json (HTTP ${response.statusCode})');
    }
    if (response.bodyBytes.isEmpty) {
      throw FDroidStoreException('index-v2.json retornou vazio ($_indexUrl)');
    }

    try {
      return utf8.decode(response.bodyBytes);
    } catch (e) {
      throw FDroidStoreException('Erro ao decodificar UTF-8 do index F-Droid: $e');
    }
  }

  void dispose() => _client.close();
}

class _ParseArgs {
  final String rawJson;
  final String repoBaseUrl;
  final String repoLabel;
  _ParseArgs(this.rawJson, this.repoBaseUrl, this.repoLabel);
}

/// Função top-level: obrigatória para rodar via `compute` em outro isolate.
List<StoreApp> _parseIndexV2(_ParseArgs args) {
  late Map<String, dynamic> root;
  try {
    root = jsonDecode(args.rawJson) as Map<String, dynamic>;
  } catch (e) {
    throw FDroidStoreException('JSON malformado no index-v2.json: $e');
  }

  final packages = root['packages'] as Map<String, dynamic>?;
  if (packages == null || packages.isEmpty) return [];

  final apps = <StoreApp>[];

  packages.forEach((packageName, packageDataRaw) {
    try {
      final packageData = packageDataRaw as Map<String, dynamic>;
      final metadata = packageData['metadata'] as Map<String, dynamic>?;
      final versions = packageData['versions'] as Map<String, dynamic>?;
      if (metadata == null || versions == null || versions.isEmpty) return;

      // Seleciona a versão mais recente pelo maior versionCode do manifest.
      Map<String, dynamic>? best;
      int bestCode = -1;
      for (final v in versions.values) {
        final vm = v as Map<String, dynamic>;
        final manifest = vm['manifest'] as Map<String, dynamic>?;
        final code = (manifest?['versionCode'] as num?)?.toInt() ?? -1;
        if (code >= bestCode) {
          bestCode = code;
          best = vm;
        }
      }
      if (best == null) return;

      final manifest = best['manifest'] as Map<String, dynamic>?;
      final file = best['file'] as Map<String, dynamic>?;
      final apkPath = file?['name'] as String?;
      if (apkPath == null || apkPath.isEmpty) return;

      final downloadUrl = '${args.repoBaseUrl}$apkPath'; // .apk direto, sem zip

      final name = _localized(metadata['name']) ?? packageName;
      final summary = _localized(metadata['summary']) ?? '';
      final description = _localized(metadata['description']) ??
          (summary.isEmpty ? 'Sem descrição.' : summary);
      final iconRel = _localizedIcon(metadata['icon']);
      final iconUrl = iconRel != null ? '${args.repoBaseUrl}$iconRel' : '';
      final versionName = manifest?['versionName'] as String? ?? 'desconhecida';

      apps.add(StoreApp(
        id: packageName,
        title: name,
        version: versionName,
        versionCode: bestCode,
        iconUrl: iconUrl,
        downloadUrl: downloadUrl,
        description: description,
        source: 'fdroid',
        packageName: packageName,
        repoLabel: args.repoLabel,
      ));
    } catch (_) {
      // Pacote malformado é ignorado; o parsing dos demais continua.
    }
  });

  return apps;
}

String? _localized(dynamic field) {
  if (field == null) return null;
  if (field is String) return field;
  if (field is Map) {
    if (field.containsKey('en-US')) return field['en-US'] as String?;
    if (field.isNotEmpty) return field.values.first as String?;
  }
  return null;
}

String? _localizedIcon(dynamic field) {
  if (field == null) return null;
  if (field is Map) {
    Map<String, dynamic>? entry;
    if (field.containsKey('en-US')) {
      entry = field['en-US'] as Map<String, dynamic>?;
    } else if (field.isNotEmpty) {
      entry = field.values.first as Map<String, dynamic>?;
    }
    return entry?['name'] as String?;
  }
  return null;
}
