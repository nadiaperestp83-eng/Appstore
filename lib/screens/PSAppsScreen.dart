import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:playstore_flutter/components/PSAppsForYouComponent.dart';
import 'package:playstore_flutter/components/PSGEditorChoiceFragment.dart';
import 'package:playstore_flutter/components/PSTopChartsFragment.dart';
import 'package:playstore_flutter/model/PSAppbarModel.dart';
import 'package:playstore_flutter/model/PSModel.dart';
import 'package:playstore_flutter/screens/PSGameViewAllScreen.dart';
import 'package:playstore_flutter/utils/PSColor.dart';
import 'package:playstore_flutter/utils/PSDataProvider.dart';
import 'package:playstore_flutter/utils/PSWidgets.dart';

class PSAppsScreen extends StatefulWidget {
  static String tag = '/PSAppsScreen';
  final List<PSAppbarModel> list = getGameList;

  @override
  PSAppsScreenState createState() => PSAppsScreenState();
}

class PSAppsScreenState extends State<PSAppsScreen> with TickerProviderStateMixin {
  List<PSAppbarModel> list = appsList;
  List<CategoriesApps> categoriesList = getCategoriesListApp();

  TabController? _tabController;
  int tabIndex = 0;

  // ===== Novo: apps reais (GitHub + F-Droid) via o motor =====
  // Para adicionar repositórios do GitHub, preencha githubRepos abaixo,
  // ex: ['Genymobile/scrcpy', 'termux/termux-app'].
  late Future<List<PSGameModel>> _realAppsFuture;

  @override
  void initState() {
    super.initState();
    init();
    _realAppsFuture = getRealAppsList(
      githubRepos: const [],
    );
  }

  init() async {
    _tabController = TabController(vsync: this, initialIndex: tabIndex, length: appsList.length);
  }

  @override
  void dispose() {
    super.dispose();
    _tabController?.dispose();
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  Widget _realAppsSection() {
    return FutureBuilder<List<PSGameModel>>(
      future: _realAppsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 100,
            alignment: Alignment.center,
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Container(
            padding: EdgeInsets.all(16),
            child: Text('Não foi possível carregar os apps reais agora.', style: secondaryTextStyle()),
          );
        }

        final apps = snapshot.data ?? [];
        if (apps.isEmpty) return SizedBox();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            16.height,
            Text('Apps reais (GitHub / F-Droid)', style: boldTextStyle(size: 18)).paddingOnly(left: 16, right: 16),
            8.height,
            SingleChildScrollView(
              padding: EdgeInsets.only(left: 8, right: 8),
              scrollDirection: Axis.horizontal,
              child: Row(
                children: apps.map((app) => PSAppsForYouComponent(app)).toList(),
              ),
            ),
            16.height,
          ],
        );
      },
    );
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
                  tabs: appsList.map((e) {
                    return Tab(text: e.name.validate());
                  }).toList(),
                  onTap: (i) {
                    tabIndex = i;
                    setState(() {});
                  },
                ),
              ),
            ),
            _realAppsSection(),
            forYouList(context, tabIndex, list, categoriesList),
          ],
        ),
      ),
    );
  }
}

Widget forYouList(BuildContext context, int tabIndex, List<PSAppbarModel> list, List<CategoriesApps> categoriesList) {
  if (tabIndex == 0) {
    return Column(
      children: list[tabIndex].categories!.map((e) {
        return Container(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              16.height,
              InkWell(
                onTap: () {
                  PSGameViewAllScreen(data: e).launch(context);
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(e.name!, style: boldTextStyle(size: 18)),
                    Icon(Icons.arrow_forward_rounded),
                  ],
                ).paddingOnly(left: 16, right: 16),
              ),
              8.height,
              SingleChildScrollView(
                padding: EdgeInsets.only(left: 8, right: 8),
                child: Row(
                  children: e.list!.map((e) {
                    return PSAppsForYouComponent(e);
                  }).toList(),
                ),
                scrollDirection: Axis.horizontal,
              ),
            ],
          ),
        );
      }).toList(),
    ).paddingBottom(16);
  } else if (tabIndex == 1) {
    return PSTopChartsFragment(tabIndex).paddingBottom(16);
  } else if (tabIndex == 2) {
    return CategoriesList(data: categoriesList);
  } else if (tabIndex == 3) {
    return PSGEditorChoiceFragment(tabIndex);
  } else {
    return SizedBox();
  }
}
