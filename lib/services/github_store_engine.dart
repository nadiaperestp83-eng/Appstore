import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/store_app.dart';

class GithubStoreException implements Exception {
  final String message;
  GithubStoreException(this.message);
  @override
  String toString() => 'GithubStoreException: $message';
}

/// Motor leve para buscar releases (.apk) de múltiplos repositórios do GitHub.
class GithubStoreEngine {
  final http.Client _client;
  static const String _baseUrl = 'https://api.github.com/repos';

  GithubStoreEngine({http.Client? client}) : _client = client ?? http.Client();

  /// Busca a release mais recente de cada repositório em [repos]
  /// (formato "owner/repo") e agrega tudo em uma única lista de StoreApp.
  /// Falhas individuais de um repo não derrubam a busca dos demais.
  Future<List<StoreApp>> fetchLatestApps(List<String> repos) async {
    final results = await Future.wait(
      repos.map((r) async {
        try {
          return await _fetchRepoApps(r);
        } catch (e) {
          // Loga e segue com lista vazia para não quebrar a agregação
          // ignore: avoid_print
          print('[GithubStoreEngine] Falha em "$r": $e');
          return <StoreApp>[];
        }
      }),
    );
    return results.expand((apps) => apps).toList();
  }

  Future<List<StoreApp>> _fetchRepoApps(String ownerRepo) async {
    final parts = ownerRepo.split('/');
    if (parts.length != 2 || parts[0].isEmpty || parts[1].isEmpty) {
      throw GithubStoreException('Formato inválido de repositório: "$ownerRepo". Use "owner/repo".');
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

    // Ícone: releases não trazem ícone, então usamos o avatar do dono do repo
    if (apps.isNotEmpty) {
      final iconUrl = await _fetchOwnerAvatar(owner, repo, ownerRepo);
      return apps.map((a) => StoreApp(
        id: a.id,
        title: a.title,
        version: a.version,
        iconUrl: iconUrl,
        downloadUrl: a.downloadUrl,
        description: a.description,
        source: a.source,
      )).toList();
    }
    return apps;
  }

  Future<String> _fetchOwnerAvatar(String owner, String repo, String ownerRepo) async {
    try {
      final repoInfo = await _getJson('$_baseUrl/$owner/$repo', ownerRepo);
      final owner_ = repoInfo is Map ? repoInfo['owner'] : null;
      return (owner_ is Map ? owner_['avatar_url'] as String? : null) ?? '';
    } catch (_) {
      return '';
    }
  }

  Future<dynamic> _getJson(String url, String context) async {
    late http.Response response;
    try {
      response = await _client
          .get(Uri.parse(url), headers: {'Accept': 'application/vnd.github+json'})
          .timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw GithubStoreException('Timeout ao acessar "$context"');
    } on http.ClientException catch (e) {
      throw GithubStoreException('Erro de rede em "$context": $e');
    } catch (e) {
      throw GithubStoreException('Erro inesperado em "$context": $e');
    }

    if (response.statusCode == 404) {
      throw GithubStoreException('Não encontrado: "$context"');
    }
    if (response.statusCode == 403) {
      throw GithubStoreException('Rate limit da API do GitHub atingido para "$context"');
    }
    if (response.statusCode != 200) {
      throw GithubStoreException('HTTP ${response.statusCode} em "$context"');
    }

    try {
      return jsonDecode(response.body);
    } catch (e) {
      throw GithubStoreException('JSON inválido em "$context": $e');
    }
  }

  List<StoreApp> _mapReleaseToApps(Map<String, dynamic> release, String ownerRepo, String repo) {
    final assets = (release['assets'] as List<dynamic>?) ?? [];
    final apkAssets = assets.where((a) {
      final name = (a is Map ? a['name'] as String? : null) ?? '';
      return name.toLowerCase().endsWith('.apk');
    }).toList();

    if (apkAssets.isEmpty) return [];

    final version = (release['tag_name'] as String?) ??
        (release['name'] as String?) ??
        'desconhecida';
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
        source: 'github',
      );
    }).toList();
  }

  void dispose() => _client.close();
}
