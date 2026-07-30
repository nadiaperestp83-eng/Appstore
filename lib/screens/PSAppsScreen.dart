import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:playstore_flutter/components/PSTopChartsFragment.dart';
import 'package:playstore_flutter/components/apple/AppleAppListTile.dart';
import 'package:playstore_flutter/components/apple/AppleFeaturedCard.dart';
import 'package:playstore_flutter/components/apple/AppleGroupedCard.dart';
import 'package:playstore_flutter/model/PSAppbarModel.dart';
import 'package:playstore_flutter/model/PSModel.dart';
import 'package:playstore_flutter/screens/PSGameViewAllScreen.dart';
import 'package:playstore_flutter/utils/AppleColors.dart';
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
      color: AppleColors.backgroundSecondary,
      padding: EdgeInsets.only(top: 8),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 46,
              color: AppleColors.background,
              child: Container(
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppleColors.divider, width: 1))),
                child: TabBar(
                  unselectedLabelColor: AppleColors.textSecondary,
                  controller: _tabController,
                  indicatorColor: AppleColors.accentBlue,
                  indicatorWeight: 2.5,
                  labelColor: AppleColors.accentBlue,
                  indicatorSize: TabBarIndicatorSize.label,
                  labelStyle: boldTextStyle(size: 13),
                  unselectedLabelStyle: primaryTextStyle(size: 13),
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
        return _ForYouSections(future: _forYouFuture, sectionOrder: gamesAppsForYouSectionOrder).paddingBottom(100);
      case 1:
        return PSTopChartsFragment(sectionsFuture: _topChartsFuture, sectionOrder: appsTopChartsSectionNames).paddingBottom(100);
      case 2:
        return CategoriesList(data: _categoriesList).paddingBottom(100);
      default:
        return SizedBox();
    }
  }
}

/// Ordem de exibição das seções reais de [getAptoideAppsBySection].
/// "More Apps" (a última) mistura Aptoide + Obtainium (Direct/HTML) - ver
/// o comentário de [getAptoideAppsBySection] em PSDataProvider.dart.
const List<String> gamesAppsForYouSectionOrder = [
  'Recommended for you',
  'Educational apps',
  'Music Players',
  'More Apps',
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
            child: Text('Não foi possível carregar os apps agora.', style: secondaryTextStyle(color: AppleColors.textSecondary)),
          );
        }

        final sections = snapshot.data ?? {};
        final nonEmptySections = sectionOrder.where((name) => (sections[name] ?? []).isNotEmpty).toList();

        if (nonEmptySections.isEmpty) {
          return Container(
            padding: EdgeInsets.symmetric(vertical: 48, horizontal: 16),
            alignment: Alignment.center,
            child: Text('Nenhum app encontrado.', style: secondaryTextStyle(color: AppleColors.textSecondary)),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: nonEmptySections.map((name) {
            final list = sections[name]!;
            // A primeira seção real vira o carrossel de destaque
            // "Recommended for you", no padrão de banner imersivo da
            // App Store. As demais viram listas minimalistas com
            // expansão inline por item.
            final bool isFeatured = name == nonEmptySections.first;
            return isFeatured ? _buildFeaturedSection(context, name, list) : _buildListSection(context, name, list);
          }).toList(),
        );
      },
    );
  }

  Widget _buildFeaturedSection(BuildContext context, String name, List<PSGameModel> list) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recommended for you',
          style: boldTextStyle(color: AppleColors.textPrimary, size: 22),
        ).paddingOnly(left: 16, right: 16),
        4.height,
        Text(
          'Escolhidos para você com base no que você usa',
          style: secondaryTextStyle(color: AppleColors.textSecondary, size: 13),
        ).paddingOnly(left: 16, right: 16),
        16.height,
        SizedBox(
          height: 340,
          child: ListView.builder(
            padding: EdgeInsets.only(left: 16, right: 4),
            scrollDirection: Axis.horizontal,
            itemCount: list.length,
            itemBuilder: (context, index) {
              final item = list[index];
              return AppleFeaturedCard(
                data: item,
                eyebrow: index == 0 ? 'Em destaque' : null,
                onTap: () {
                  final sectionModel = PSAppbarModel(name: name, list: list);
                  PSGameViewAllScreen(data: sectionModel).launch(context);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildListSection(BuildContext context, String name, List<PSGameModel> list) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        28.height,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(name, style: boldTextStyle(color: AppleColors.textPrimary, size: 20)),
            InkWell(
              onTap: () {
                final sectionModel = PSAppbarModel(name: name, list: list);
                PSGameViewAllScreen(data: sectionModel).launch(context);
              },
              child: Text('See All', style: primaryTextStyle(color: AppleColors.accentBlue, size: 14)),
            ),
          ],
        ).paddingOnly(left: 16, right: 16),
        12.height,
        AppleGroupedCard(
          dividerIndent: 84,
          children: list.map((item) => AppleAppListTile(data: item)).toList(),
        ),
      ],
    );
  }
}
