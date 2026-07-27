import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:playstore_flutter/components/PSAppsForYouComponent.dart';
import 'package:playstore_flutter/components/PSTopChartsFragment.dart';
import 'package:playstore_flutter/model/PSAppbarModel.dart';
import 'package:playstore_flutter/model/PSModel.dart';
import 'package:playstore_flutter/screens/PSGameViewAllScreen.dart';
import 'package:playstore_flutter/utils/PSColor.dart';
import 'package:playstore_flutter/utils/PSDataProvider.dart';
import 'package:playstore_flutter/utils/PSWidgets.dart';

/// Aba "Apps", 100% conectada ao motor do Aptoide.
///
/// O tab "Editor's Choice" saiu de vez (era mockado, sem equivalente real).
/// A seção "Premium apps" já nem existia mais nas queries reais - ela só
/// sobrevivia como fallback mockado enquanto a resposta do Aptoide não
/// chegava. Esse fallback também saiu: agora, enquanto carrega, a tela
/// mostra um indicador de progresso de verdade, nunca dado inventado.
class PSAppsScreen extends StatefulWidget {
  static String tag = '/PSAppsScreen';

  @override
  PSAppsScreenState createState() => PSAppsScreenState();
}

const List<String> _appsTabNames = ['For you', 'Top Charts', 'Categories'];

class PSAppsScreenState extends State<PSAppsScreen> with TickerProviderStateMixin {
  final List<CategoriesApps> _categoriesList = getCategoriesListApp();

  TabController? _tabController;
  int tabIndex = 0;

  // Buscadas uma única vez em initState: trocar de tab não deve refazer a
  // requisição de rede (isso é o que causava a sensação de "recarregar do
  // zero" e o "flash" de dado mockado antes do real aparecer).
  late final Future<Map<String, List<PSGameModel>>> _forYouFuture;
  late final Future<Map<String, List<PSGameModel>>> _topChartsFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(vsync: this, initialIndex: tabIndex, length: _appsTabNames.length);
    _forYouFuture = getAptoideAppsBySection(perSectionLimit: 20);
    _topChartsFuture = getAptoideAppsCategorySections(appsTopChartsSectionNames, perSectionLimit: 20);
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
                  unselectedLabelColor: Colors.black54,
                  controller: _tabController,
                  indicatorColor: Colors.green,
                  labelColor: psColorGreen,
                  indicatorSize: TabBarIndicatorSize.label,
                  labelStyle: boldTextStyle(size: 12),
                  isScrollable: true,
                  tabs: _appsTabNames.map((name) => Tab(text: name)).toList(),
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
        return _ForYouSections(future: _forYouFuture, sectionOrder: gamesAppsForYouSectionOrder).paddingBottom(16);
      case 1:
        return PSTopChartsFragment(sectionsFuture: _topChartsFuture, sectionOrder: appsTopChartsSectionNames).paddingBottom(16);
      case 2:
        return CategoriesList(data: _categoriesList);
      default:
        return SizedBox();
    }
  }
}

/// Ordem de exibição das seções reais de [getAptoideAppsBySection].
const List<String> gamesAppsForYouSectionOrder = [
  'Recommended for you',
  'Educational apps',
  'Music Players',
  'Tools & utilities',
];

/// Carrosséis "For you" da aba Apps - mesmo comportamento honesto de
/// loading/erro/vazio usado na aba Games: nunca mostra dado inventado
/// enquanto espera a resposta real do Aptoide.
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
            child: Text('Não foi possível carregar os apps agora.', style: secondaryTextStyle()),
          );
        }

        final sections = snapshot.data ?? {};
        final nonEmptySections = sectionOrder.where((name) => (sections[name] ?? []).isNotEmpty).toList();

        if (nonEmptySections.isEmpty) {
          return Container(
            padding: EdgeInsets.symmetric(vertical: 48, horizontal: 16),
            alignment: Alignment.center,
            child: Text('Nenhum app encontrado.', style: secondaryTextStyle()),
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
                8.height,
                SingleChildScrollView(
                  padding: EdgeInsets.only(left: 8, right: 8),
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: list.map((e) => PSAppsForYouComponent(e)).toList(),
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
