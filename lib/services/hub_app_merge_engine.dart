import '../models/store_app.dart';
import 'hub_app.dart';

/// Agrupa uma lista de [StoreApp] (vindos de vários motores/repositórios)
/// em [HubApp]s únicos, evitando duplicar o card do mesmo pacote na tela
/// principal quando ele existe em mais de uma fonte.
///
/// Limitação conhecida: apps vindos do GitHub não têm o packageName real
/// (ele só existe dentro do .apk, que não baixamos antecipadamente), então
/// cada release do GitHub vira o seu próprio HubApp — só apps do F-Droid
/// (ou repositórios compatíveis, que sempre indexam pelo packageName real)
/// participam do merge entre si.
class HubAppMergeEngine {
  /// [preferredRepoOrder] permite priorizar um repositório específico
  /// (ex: sempre preferir "F-Droid oficial" sobre um repo customizado)
  /// mesmo quando outro tiver versionCode maior. Ordem do mais preferido
  /// pro menos preferido, usando o mesmo texto de [StoreApp.repoLabel].
  /// Se vazio, o critério é só o maior versionCode.
  final List<String> preferredRepoOrder;

  HubAppMergeEngine({this.preferredRepoOrder = const []});

  List<HubApp> merge(List<StoreApp> apps) {
    final Map<String, List<StoreApp>> grouped = {};

    for (final app in apps) {
      final key = (app.packageName != null && app.packageName!.isNotEmpty) ? 'pkg:${app.packageName}' : 'solo:${app.id}';
      grouped.putIfAbsent(key, () => []).add(app);
    }

    final List<HubApp> result = [];

    grouped.forEach((key, group) {
      final sources = group.map(AppSourceOption.fromStoreApp).toList();

      // Segurança: se o mesmo packageName aparecer em fontes diferentes,
      // isso normalmente é o esperado (várias origens do mesmo app). O que
      // este motor NÃO faz é verificar se a assinatura do APK bate entre
      // as fontes (exigiria baixar e inspecionar o .apk de cada uma).
      // Enquanto isso não existir, trate fontes "não oficiais" com cautela
      // ao atualizar um app já instalado por outra fonte.
      final primary = group.first;

      final hubApp = HubApp(
        packageName: primary.packageName ?? primary.id,
        title: primary.title,
        description: primary.description,
        availableSources: sources,
        preferredSourceId: _resolvePreferred(sources),
      );

      result.add(hubApp);
    });

    return result;
  }

  String _resolvePreferred(List<AppSourceOption> sources) {
    if (preferredRepoOrder.isNotEmpty) {
      for (final preferred in preferredRepoOrder) {
        final match = sources.where((s) => s.repoLabel == preferred);
        if (match.isNotEmpty) {
          final best = [...match]..sort((a, b) => b.versionCode.compareTo(a.versionCode));
          return best.first.sourceId;
        }
      }
    }
    final sorted = [...sources]..sort((a, b) => b.versionCode.compareTo(a.versionCode));
    return sorted.first.sourceId;
  }
}
