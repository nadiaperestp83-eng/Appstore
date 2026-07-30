import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/obtainium_app_entry.dart';
import '../models/store_app.dart';
import 'codeberg_store_engine.dart';
import 'github_store_engine.dart';

class ObtainiumCatalogException implements Exception {
  final String message;
  ObtainiumCatalogException(this.message);
  @override
  String toString() => 'ObtainiumCatalogException: $message';
}

/// Integração com o catálogo comunitário do Obtainium
/// (https://github.com/ImranR98/Obtainium).
///
/// O Obtainium em si NÃO é uma API de loja - é um app cliente que instala
/// apps a partir da página de release de cada um, configurado app por
/// app. O que este motor consome de verdade é a lista comunitária de apps
/// já configurados, publicada em apps.obtainium.imranr.dev e mantida como
/// um arquivo JSON por app no repositório
/// github.com/ImranR98/apps.obtainium.imranr.dev (pasta `data/apps`).
///
/// Pra listar esse catálogo (~230 apps) sem gastar o limite de 60
/// requisições/hora da API do GitHub (sem token), usamos o CDN público do
/// jsDelivr (data.jsdelivr.com + cdn.jsdelivr.net), que espelha qualquer
/// repositório público do GitHub e não tem esse limite. A API do GitHub
/// (ou do Codeberg) só entra depois, e só pra resolver o link real de
/// download de cada app já filtrado - ver [fetchResolvedApps].
///
/// Fontes de apps do catálogo do Obtainium que sabemos resolver de
/// verdade nesta versão: GitHub, Codeberg, link direto de .apk e o
/// fallback "HTML" genérico do próprio Obtainium (baixar uma página e
/// pegar o link de .apk nela). GitLab, lojas de app regionais (APKPure,
/// Uptodown, Huawei AppGallery etc.), Jenkins, Telegram e afins ainda
/// ficam de fora - preferimos mostrar menos apps a inventar um link de
/// download que não sabemos gerar de verdade.
class ObtainiumCatalogEngine {
  static const String _repo = 'ImranR98/apps.obtainium.imranr.dev';
  static const String _branch = 'main';
  static const String _dataPath = '/data/apps/';

  final http.Client _client;

  ObtainiumCatalogEngine({http.Client? client}) : _client = client ?? http.Client();

  // Cache em memória do processo: o catálogo inteiro só é buscado uma vez
  // por sessão do app (ele muda pouco, e cada entrada é um arquivo
  // pequeno) - evita refazer ~230 requisições toda vez que o usuário troca
  // de aba ou toca numa categoria.
  static List<ObtainiumAppEntry>? _cachedCatalog;
  static Future<List<ObtainiumAppEntry>>? _inFlightCatalog;

  Future<List<ObtainiumAppEntry>> _loadCatalog() {
    final cached = _cachedCatalog;
    if (cached != null) return Future.value(cached);
    final inFlight = _inFlightCatalog;
    if (inFlight != null) return inFlight;

    final future = _fetchCatalog().then((catalog) {
      _cachedCatalog = catalog;
      _inFlightCatalog = null;
      return catalog;
    }).catchError((e) {
      _inFlightCatalog = null;
      throw e;
    });
    _inFlightCatalog = future;
    return future;
  }

  Future<List<ObtainiumAppEntry>> _fetchCatalog() async {
    final indexUrl = 'https://data.jsdelivr.com/v1/package/gh/$_repo@$_branch/flat';
    final indexRaw = await _get(indexUrl);
    final indexJson = jsonDecode(indexRaw);
    final files = ((indexJson is Map ? indexJson['files'] : null) as List?) ?? const [];

    final appFilePaths = files
        .whereType<Map>()
        .map((f) => (f['name'] as String?) ?? '')
        .where((name) => name.startsWith(_dataPath) && name.endsWith('.json'))
        .toList();

    // Busca em lotes (não tudo de uma vez, nem um por um) - o jsDelivr não
    // tem o limite de 60/h do GitHub, mas ainda assim é gentil disparar em
    // lotes pequenos em vez de ~230 requisições simultâneas.
    const batchSize = 20;
    final entries = <ObtainiumAppEntry>[];
    for (var i = 0; i < appFilePaths.length; i += batchSize) {
      final batch = appFilePaths.skip(i).take(batchSize);
      final batchResults = await Future.wait(batch.map((path) => _fetchEntry(path).catchError((e) {
            // ignore: avoid_print
            print('[ObtainiumCatalogEngine] Falha ao ler "$path": $e');
            return null;
          })));
      entries.addAll(batchResults.whereType<ObtainiumAppEntry>());
    }
    return entries;
  }

  Future<ObtainiumAppEntry?> _fetchEntry(String path) async {
    final fileName = path.split('/').last; // ex: "com.retroarch.json"
    final id = fileName.replaceAll('.json', '');
    final url = 'https://cdn.jsdelivr.net/gh/$_repo@$_branch$path';
    final raw = await _get(url);
    final json = jsonDecode(raw);
    if (json is! Map) return null;
    return ObtainiumAppEntry.fromJson(id, json.cast<String, dynamic>());
  }

  Future<String> _get(String url) async {
    late http.Response response;
    try {
      response = await _client.get(Uri.parse(url)).timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw ObtainiumCatalogException('Timeout ao acessar "$url"');
    } on http.ClientException catch (e) {
      throw ObtainiumCatalogException('Erro de rede em "$url": $e');
    } catch (e) {
      throw ObtainiumCatalogException('Erro inesperado em "$url": $e');
    }
    if (response.statusCode != 200) {
      throw ObtainiumCatalogException('HTTP ${response.statusCode} em "$url"');
    }
    return response.body;
  }

  /// Retorna apps do catálogo do Obtainium cujas categorias reais batem
  /// com [categorySlugs] (ex: `['games']`, `['finance']`), já com o link
  /// de download REAL resolvido (release mais recente no GitHub ou
  /// Codeberg). Se [categorySlugs] for nulo ou vazio, não filtra por
  /// categoria - varre o catálogo inteiro.
  ///
  /// [limit] limita quantos apps têm o download RESOLVIDO nesta chamada
  /// (cada um custa 1-2 requisições à API do GitHub/Codeberg, que TÊM
  /// limite de taxa sem token) - a listagem/filtragem em si (via jsDelivr)
  /// não é afetada por esse limite.
  Future<List<StoreApp>> fetchResolvedApps({List<String>? categorySlugs, int limit = 15}) async {
    final catalog = await _loadCatalog();

    final filtered = (categorySlugs == null || categorySlugs.isEmpty)
        ? catalog
        : catalog.where((e) => e.categories.any((c) => categorySlugs.contains(c))).toList();

    final selectedGithub = <String, ObtainiumAppEntry>{}; // "dono/repo" -> entrada
    final selectedCodeberg = <String, ObtainiumAppEntry>{};

    for (final entry in filtered) {
      if (selectedGithub.length + selectedCodeberg.length >= limit) break;
      final resolved = entry.firstResolution;
      if (resolved == null) continue;
      if (resolved.kind == 'github') {
        selectedGithub[resolved.target] = entry;
      } else if (resolved.kind == 'codeberg') {
        selectedCodeberg[resolved.target] = entry;
      }
    }

    final github = GithubStoreEngine();
    final codeberg = CodebergStoreEngine();

    List<StoreApp> githubApps = [];
    List<StoreApp> codebergApps = [];
    try {
      final results = await Future.wait([
        selectedGithub.isEmpty ? Future.value(<StoreApp>[]) : github.fetchLatestApps(selectedGithub.keys.toList()),
        selectedCodeberg.isEmpty ? Future.value(<StoreApp>[]) : codeberg.fetchLatestApps(selectedCodeberg.keys.toList()),
      ]);
      githubApps = results[0];
      codebergApps = results[1];
    } finally {
      github.dispose();
      codeberg.dispose();
    }

    final resolved = <StoreApp>[];
    resolved.addAll(_enrichRepoApps(githubApps, selectedGithub, 'GitHub'));
    resolved.addAll(_enrichRepoApps(codebergApps, selectedCodeberg, 'Codeberg'));
    return resolved;
  }

  /// Apps do Obtainium que NÃO são de um repositório de código (GitHub/
  /// Codeberg) - ou seja, "Direct APK Link" (a própria URL já é o .apk) e
  /// o fallback "HTML" (uma página com um link de .apk dentro). Usado pra
  /// popular a seção "More Apps" das abas Games/Apps, que também recebe
  /// apps que não são necessariamente open source (o Obtainium rastreia
  /// releases direto do site oficial de vários apps fechados/freeware,
  /// não só projetos open source).
  ///
  /// Diferente de [fetchResolvedApps], aqui não filtramos por categoria -
  /// "More Apps" é deliberadamente um balaio geral.
  Future<List<StoreApp>> fetchMoreApps({int limit = 15}) async {
    final catalog = await _loadCatalog();

    final directEntries = <ObtainiumAppEntry, String>{}; // entrada -> url do .apk
    final htmlEntries = <ObtainiumAppEntry, String>{}; // entrada -> url da página

    for (final entry in catalog) {
      if (directEntries.length + htmlEntries.length >= limit) break;
      final resolved = entry.firstResolution;
      if (resolved == null) continue;
      if (resolved.kind == 'direct') {
        directEntries[entry] = resolved.target;
      } else if (resolved.kind == 'html') {
        htmlEntries[entry] = resolved.target;
      }
    }

    final apps = <StoreApp>[];

    // "Direct APK Link": a própria URL já é o arquivo final, não precisa
    // resolver nada.
    directEntries.forEach((entry, apkUrl) {
      apps.add(StoreApp(
        id: 'obtainium::${entry.id}',
        title: entry.name,
        version: '',
        iconUrl: entry.iconUrl,
        downloadUrl: apkUrl,
        description: entry.description.isEmpty ? 'Sem descrição.' : entry.description,
        source: 'obtainium',
        packageName: entry.id,
        repoLabel: 'Obtainium (Link direto): ${entry.name}',
        categories: entry.categories,
      ));
    });

    // Fallback "HTML": baixa a página e procura o primeiro link pra um
    // .apk - se a página não carregar ou não tiver link nenhum, o app
    // fica de fora (nunca inventamos um link que não achamos de verdade).
    final htmlResults = await Future.wait(htmlEntries.entries.map((e) async {
      final apkUrl = await _resolveHtmlApkLink(e.value);
      return apkUrl == null ? null : MapEntry(e.key, apkUrl);
    }));

    for (final result in htmlResults) {
      if (result == null) continue;
      final entry = result.key;
      apps.add(StoreApp(
        id: 'obtainium::${entry.id}',
        title: entry.name,
        version: '',
        iconUrl: entry.iconUrl,
        downloadUrl: result.value,
        description: entry.description.isEmpty ? 'Sem descrição.' : entry.description,
        source: 'obtainium',
        packageName: entry.id,
        repoLabel: 'Obtainium (HTML): ${entry.name}',
        categories: entry.categories,
      ));
    }

    return apps;
  }

  /// Baixa [pageUrl] e procura o primeiro `href="...alguma-coisa.apk"` nela,
  /// resolvendo links relativos contra a própria URL da página. Retorna
  /// null se a página falhar ou não tiver nenhum link de .apk - nunca
  /// inventa um link.
  Future<String?> _resolveHtmlApkLink(String pageUrl) async {
    try {
      final response = await _client.get(Uri.parse(pageUrl)).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return null;

      final matches = RegExp(r'''(?:href|src)\s*=\s*["']([^"']+\.apk)["']''', caseSensitive: false).allMatches(response.body);
      for (final match in matches) {
        final href = match.group(1);
        if (href == null || href.isEmpty) continue;
        return Uri.parse(pageUrl).resolve(href).toString();
      }
      return null;
    } catch (e) {
      // ignore: avoid_print
      print('[ObtainiumCatalogEngine] Fallback HTML falhou em "$pageUrl": $e');
      return null;
    }
  }

  /// Substitui o título/ícone/descrição "crus" do release (github/codeberg)
  /// pelos metadados mais ricos que o Obtainium já tem pro app (nome
  /// "bonito", ícone, descrição, categorias reais), mantendo o link de
  /// download real resolvido.
  List<StoreApp> _enrichRepoApps(List<StoreApp> apps, Map<String, ObtainiumAppEntry> byOwnerRepo, String labelPrefix) {
    return apps.map((app) {
      final ownerRepo = app.id.split('::').first;
      final entry = byOwnerRepo[ownerRepo];
      return StoreApp(
        id: 'obtainium::${entry?.id ?? app.id}',
        title: entry?.name ?? app.title,
        version: app.version,
        versionCode: app.versionCode,
        iconUrl: (entry?.iconUrl.isNotEmpty ?? false) ? entry!.iconUrl : app.iconUrl,
        downloadUrl: app.downloadUrl,
        description: (entry?.description.isNotEmpty ?? false) ? entry!.description : app.description,
        source: 'obtainium',
        packageName: entry?.id,
        repoLabel: 'Obtainium ($labelPrefix): ${entry?.name ?? app.title}',
        categories: entry?.categories ?? app.categories,
      );
    }).toList();
  }

  void dispose() => _client.close();
}
