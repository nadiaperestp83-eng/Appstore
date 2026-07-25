import '../models/store_app.dart';
import 'github_store_engine.dart';
import 'fdroid_store_engine.dart';

/// Agrega os motores GitHub + F-Droid em uma única fonte de busca para a loja.
class AppStoreAggregator {
  final GithubStoreEngine githubEngine;
  final FDroidStoreEngine fdroidEngine;

  AppStoreAggregator({
    GithubStoreEngine? githubEngine,
    FDroidStoreEngine? fdroidEngine,
  })  : githubEngine = githubEngine ?? GithubStoreEngine(),
        fdroidEngine = fdroidEngine ?? FDroidStoreEngine(); // repo oficial f-droid.org

  /// Busca em paralelo nos dois motores. [githubRepos] no formato "owner/repo".
  Future<List<StoreApp>> fetchAll({required List<String> githubRepos}) async {
    final results = await Future.wait([
      githubEngine.fetchLatestApps(githubRepos),
      fdroidEngine.fetchApps().catchError((e) {
        // ignore: avoid_print
        print('[AppStoreAggregator] F-Droid falhou: $e');
        return <StoreApp>[];
      }),
    ]);
    return [...results[0], ...results[1]];
  }

  List<StoreApp> search(List<StoreApp> apps, String query) {
    if (query.trim().isEmpty) return apps;
    final q = query.toLowerCase();
    return apps
        .where((a) =>
            a.title.toLowerCase().contains(q) ||
            a.description.toLowerCase().contains(q))
        .toList();
  }

  void dispose() {
    githubEngine.dispose();
    fdroidEngine.dispose();
  }
}
