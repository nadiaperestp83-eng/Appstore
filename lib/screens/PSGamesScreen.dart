import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:playstore_flutter/components/PSGameForYouComponent.dart';
import 'package:playstore_flutter/components/PSTopChartsFragment.dart';
import 'package:playstore_flutter/model/PSAppbarModel.dart';
import 'package:playstore_flutter/model/PSModel.dart';
import 'package:playstore_flutter/screens/PSGameViewAllScreen.dart';
import 'package:playstore_flutter/utils/PSColor.dart';
import 'package:playstore_flutter/utils/PSDataProvider.dart';
import 'package:playstore_flutter/utils/PSWidgets.dart';

/// Aba "Games", 100% conectada ao motor do Aptoide.
///
/// Os tabs "Events", "Premium" e "Editors'Choice" saíram de vez: eram
/// puramente mockados e não têm equivalente real na API do Aptoide (não é
/// scraping de app pago, nem existe endpoint de "evento" no webservice v7).
/// Restam apenas os 3 tabs que hoje mostram dado real: "For you" (carrosséis
/// por categoria), "Top charts" (chips + lista) e "Categories" (navegação
/// por categoria, sempre foi estático/local, não é "mock de app").
class PSGamesScreen extends StatefulWidget {
  static String tag = '/PSGamesScreen';

  @override
  PSGamesScreenState createState() => PSGamesScreenState();
}

const List<String> _gamesTabNames = ['For you', 'Top charts', 'Categories'];

class PSGamesScreenState extends State<PSGamesScreen> with TickerProviderStateMixin {
  final List<CategoriesApps> _categoriesList = getCategoriesList();

  TabController? _tabController;
  int tabIndex = 0;

  // Buscadas uma única vez (não a cada rebuild/troca de tab) para não gerar
  // loop de load: trocar de tab só troca o widget exibido, não refaz a
  // requisição de rede.
  late final Future<Map<String, List<PSGameModel>>> _forYouFuture;
  late final Future<Map<String, List<PSGameModel>>> _topChartsFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(vsync: this, initialIndex: tabIndex, length: _gamesTabNames.length);
    _forYouFuture = getAptoideGamesBySection(gamesForYouSectionNames, perSectionLimit: 15);
    _topChartsFuture = getAptoideGamesBySection(gamesTopChartsSectionNames, perSectionLimit: 20);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: context.height(),
      padding: EdgeInsets.only(top: 8),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 50,
              child: Container(
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[300]!))),
                child: TabBar(
                  indicatorSize: TabBarIndicatorSize.label,
                  unselectedLabelColor: Colors.black54,
                  labelStyle: boldTextStyle(size: 12),
                  controller: _tabController,
                  indicatorColor: Colors.green,
                  labelColor: psColorGreen,
                  isScrollable: true,
                  tabs: _gamesTabNames.map((name) => Tab(text: name)).toList(),
                  onTap: (i) {
                    tabIndex = i;
                    setState(() {});
                  },
                ),
              ),
            ),
            _buildTabContent(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(BuildContext context) {
    switch (tabIndex) {
      case 0:
        return _ForYouSections(future: _forYouFuture, sectionOrder: gamesForYouSectionNames).paddingBottom(16);
      case 1:
        return PSTopChartsFragment(sectionsFuture: _topChartsFuture, sectionOrder: gamesTopChartsSectionNames).paddingBottom(16);
      case 2:
        return CategoriesList(data: _categoriesList);
      default:
        return SizedBox();
    }
  }
}

/// Carrosséis "For you", já com estado de loading/erro/vazio - nunca mostra
/// dado inventado enquanto espera a resposta real do Aptoide.
class _ForYouSections extends StatelessWidget {
  final Future<Map<String, List<PSGameModel>>> future;
  final List<String> sectionOrder;

  const _ForYouSections({required this.future, required this.sectionOrder});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, List<PSGameModel>>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: EdgeInsets.symmetric(vertical: 48),
            alignment: Alignment.center,
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Container(
            padding: EdgeInsets.symmetric(vertical: 48, horizontal: 16),
            alignment: Alignment.center,
            child: Text('Não foi possível carregar os jogos agora.', style: secondaryTextStyle()),
          );
        }

        final sections = snapshot.data ?? {};
        final nonEmptySections = sectionOrder.where((name) => (sections[name] ?? []).isNotEmpty).toList();

        if (nonEmptySections.isEmpty) {
          return Container(
            padding: EdgeInsets.symmetric(vertical: 48, horizontal: 16),
            alignment: Alignment.center,
            child: Text('Nenhum jogo encontrado.', style: secondaryTextStyle()),
          );
        }

        return Column(
          children: nonEmptySections.map((name) {
            final list = sections[name]!;
            final sectionModel = PSAppbarModel(name: name, list: list);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                16.height,
                InkWell(
                  onTap: () {
                    PSGameViewAllScreen(data: sectionModel).launch(context);
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(name, style: boldTextStyle(size: 18)),
                      Icon(Icons.arrow_forward_rounded),
                    ],
                  ).paddingOnly(left: 16, right: 16),
                ),
                16.height,
                SingleChildScrollView(
                  padding: EdgeInsets.only(left: 8, right: 8),
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: list.map((e) => PSGameForYouComponent(e)).toList(),
                  ),
                ),
              ],
            );
          }).toList(),
        );
      },
    );
  }
}
