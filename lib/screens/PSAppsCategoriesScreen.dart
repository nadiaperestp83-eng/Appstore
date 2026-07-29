import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:playstore_flutter/components/apple/AppleAppListTile.dart';
import 'package:playstore_flutter/components/apple/AppleGroupedCard.dart';
import 'package:playstore_flutter/components/apple/AppleShimmerLoader.dart';
import 'package:playstore_flutter/model/PSModel.dart';
import 'package:playstore_flutter/utils/AppleColors.dart';
import 'package:playstore_flutter/utils/PSDataProvider.dart';

/// Tela de resultados de uma categoria da grade "Categories".
///
/// Busca em tempo real, em paralelo, nas 3 fontes reais que o app conhece:
/// Aptoide (seção "Apps") e F-Droid + GitHub (seção "Apps livres") - usando
/// o nome da categoria (via [categorySearchKeywords] em PSDataProvider.dart)
/// como termo de busca. Nunca mostra dado inventado: enquanto a rede
/// responde, mostra um skeleton/shimmer cinza suave ([AppleShimmerLoader]);
/// se as fontes não tiverem nada pra essa categoria, mostra um aviso claro
/// em vez de inventar itens.
class PSAppsCategoriesScreen extends StatefulWidget {
  final CategoriesApps? data;

  const PSAppsCategoriesScreen({Key? key, this.data}) : super(key: key);

  static String tag = '/PSAppsCategoriesScreen';

  @override
  PSAppsCategoriesScreenState createState() => PSAppsCategoriesScreenState();
}

class _CategoryResults {
  final List<PSGameModel> apps;
  final List<PSGameModel> freeApps;

  _CategoryResults({required this.apps, required this.freeApps});

  bool get isEmpty => apps.isEmpty && freeApps.isEmpty;
}

class PSAppsCategoriesScreenState extends State<PSAppsCategoriesScreen> {
  late final Future<_CategoryResults> _resultsFuture;

  @override
  void initState() {
    super.initState();
    _resultsFuture = _loadCategory(widget.data?.name ?? '');
  }

  /// Dispara as duas buscas reais em paralelo. Se uma fonte falhar (ex:
  /// F-Droid fora do ar), a outra ainda aparece normalmente - erro isolado
  /// numa fonte não derruba a categoria inteira.
  Future<_CategoryResults> _loadCategory(String categoryName) async {
    final results = await Future.wait([
      searchAptoideAppsByCategory(categoryName).catchError((_) => <PSGameModel>[]),
      searchFreeAppsByCategory(categoryName).catchError((_) => <PSGameModel>[]),
    ]);
    return _CategoryResults(apps: results[0], freeApps: results[1]);
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.data?.name ?? '';

    return Scaffold(
      backgroundColor: AppleColors.backgroundSecondary,
      appBar: AppBar(
        backgroundColor: AppleColors.background,
        elevation: 0,
        iconTheme: IconThemeData(color: AppleColors.textPrimary),
        title: Text(title, style: TextStyle(color: AppleColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 18)),
      ),
      body: FutureBuilder<_CategoryResults>(
        future: _resultsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Skeleton/shimmer no lugar de um spinner seco: transição fluida
            // até os dados reais chegarem.
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              children: const [
                AppleShimmerLoader(itemCount: 3),
                SizedBox(height: 16),
                AppleShimmerLoader(itemCount: 3),
              ],
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Não foi possível carregar "$title" agora.',
                style: TextStyle(color: AppleColors.textSecondary),
                textAlign: TextAlign.center,
              ).paddingSymmetric(horizontal: 24),
            );
          }

          final result = snapshot.data ?? _CategoryResults(apps: [], freeApps: []);
          if (result.isEmpty) {
            return Center(
              child: Text(
                'Nenhum app encontrado em "$title".',
                style: TextStyle(color: AppleColors.textSecondary),
                textAlign: TextAlign.center,
              ).paddingSymmetric(horizontal: 24),
            );
          }

          // Padding inferior de 120: a pílula flutuante da navbar inferior
          // não esconde nem corta o último card, mesmo quando esta tela é
          // empilhada por cima do dashboard.
          return ListView(
            padding: const EdgeInsets.only(top: 8, bottom: 120),
            children: [
              if (result.apps.isNotEmpty) ..._buildSection('Apps', result.apps),
              if (result.freeApps.isNotEmpty) ..._buildSection('Apps livres', result.freeApps),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildSection(String sectionTitle, List<PSGameModel> apps) {
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Text(sectionTitle, style: TextStyle(color: AppleColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 18)),
      ),
      AppleGroupedCard(
        dividerIndent: 84,
        children: apps.map((app) => AppleAppListTile(data: app)).toList(),
      ).paddingSymmetric(horizontal: 16),
    ];
  }
}
