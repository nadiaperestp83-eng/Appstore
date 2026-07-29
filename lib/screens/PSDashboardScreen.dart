import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:playstore_flutter/model/PSAppbarModel.dart';
import 'package:playstore_flutter/screens/PSAppsGamesScreen.dart';
import 'package:playstore_flutter/screens/PSAppsScreen.dart';
import 'package:playstore_flutter/screens/PSFreeAppsScreen.dart';
import 'package:playstore_flutter/screens/PSGamesScreen.dart';
import 'package:playstore_flutter/screens/PSNavigationScreen.dart';
import 'package:playstore_flutter/screens/PSNotificationScreen.dart';
import 'package:playstore_flutter/screens/PSPlayProtectScreen.dart';
import 'package:playstore_flutter/screens/PSSettingScreen.dart';
import 'package:playstore_flutter/utils/PSColor.dart';
import 'package:playstore_flutter/utils/PSImages.dart';

class PSDashboardScreen extends StatefulWidget {
  static String tag = '/PSDashboardScreen';

  @override
  PSDashboardScreenState createState() => PSDashboardScreenState();
}

class PSDashboardScreenState extends State<PSDashboardScreen>
    with TickerProviderStateMixin {
  GlobalKey<ScaffoldState> drawerKey = GlobalKey();
  TabController? _tabController;

  int currentIndex = 0;

  final pages = <Widget>[
    PSGamesScreen(),
    PSAppsScreen(),
    PSFreeAppsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    init();
    _tabController =
        TabController(vsync: this, initialIndex: 0, length: getGameList.length);
  }

  @override
  void dispose() {
    super.dispose();
    _tabController?.dispose();
  }

  init() async {
    //
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: drawerKey,
      appBar: PreferredSize(
        preferredSize: Size(context.width(), 140),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppScreen(),
            Container(
              child: TabBar(
                isScrollable: true,
                unselectedLabelColor: Colors.black87,
                controller: _tabController,
                indicatorColor: currentIndex == 0 || currentIndex == 1
                    ? Colors.green
                    : Colors.red[600],
                labelColor: currentIndex == 0 || currentIndex == 1
                    ? psColorGreen
                    : Colors.red[600],
                tabs: currentIndex == 0
                    ? getGameList.map((e) {
                        return Tab(text: e.name);
                      }).toList()
                    : currentIndex == 1
                        ? appsList.map((e) {
                            return Tab(text: e.name);
                          }).toList()
                        : movieList.map((e) {
                            return Tab(text: e.name);
                          }).toList(),
              ),
            ).visible(false)
          ],
        ),
      ),
      // IndexedStack em vez de `pages[currentIndex]`: mantém o State de
      // TODAS as abas vivo o tempo todo. Antes, trocar de aba tirava o
      // widget da árvore (destruindo o State) e, ao voltar, recriava tudo
      // do zero - refazendo TODAS as buscas de rede de novo. Esse era o
      // principal gerador de "loop de load" da aplicação.
      body: IndexedStack(index: currentIndex, children: pages),
      drawer: Drawer(
        child: SingleChildScrollView(
          child: Container(
            margin: EdgeInsets.all(8),
            padding: EdgeInsets.only(top: 32),
            child: Column(
              children: [
                8.height,
                Row(
                  children: [
                    Image.asset("./images/playStore/ps_playstore.png",
                            width: 30, height: 30)
                        .paddingOnly(left: 8),
                    Text('App', style: boldTextStyle()),
                  ],
                ),
                4.height,
                Divider(thickness: 1),
                ListTile(
                  visualDensity: VisualDensity(vertical: -4),
                  onTap: () {
                    finish(context);
                    PSAppsGamesScreen().launch(context);
                  },
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(MaterialCommunityIcons.apps_box,
                          size: 20, color: Colors.black54)
                      .paddingOnly(left: 8),
                  title: Text('My apps & games', style: primaryTextStyle()),
                ),
                ListTile(
                  visualDensity: VisualDensity(vertical: -2),
                  onTap: () {
                    finish(context);
                    PSNotificationScreen().launch(context);
                  },
                  contentPadding: EdgeInsets.zero,
                  leading:
                      Icon(AntDesign.bells, size: 20, color: Colors.black54)
                          .paddingOnly(left: 8),
                  title: Text('Notifications', style: primaryTextStyle()),
                ),
                Divider(thickness: 1),
                ListTile(
                  visualDensity: VisualDensity(vertical: -2),
                  onTap: () {
                    finish(context);
                    PSPlayProtectScreen().launch(context);
                  },
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(MaterialCommunityIcons.security,
                          size: 20, color: Colors.black54)
                      .paddingOnly(left: 8),
                  title: Text('Play Protect', style: primaryTextStyle()),
                ),
                ListTile(
                  visualDensity: VisualDensity(vertical: -2),
                  onTap: () {
                    finish(context);
                    PSSettingScreen().launch(context);
                  },
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.settings, size: 20, color: Colors.black54)
                      .paddingOnly(left: 8),
                  title: Text('Settings', style: primaryTextStyle()),
                ),
                Divider(thickness: 1),
                ListTile(
                  visualDensity: VisualDensity(horizontal: -4, vertical: -2),
                  contentPadding: EdgeInsets.only(left: 8),
                  title: Text('Redeem', style: boldTextStyle(size: 18)),
                ),
                ListTile(
                  visualDensity: VisualDensity(horizontal: -4, vertical: -2),
                  contentPadding: EdgeInsets.only(left: 8),
                  title: Text('Help & feedback', style: primaryTextStyle()),
                ),
                ListTile(
                  visualDensity: VisualDensity(horizontal: -4, vertical: -4),
                  contentPadding: EdgeInsets.only(left: 8),
                  title: Text('About App', style: primaryTextStyle()),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
              title: Text('Games'),
              icon: Icon(Icons.sports_esports_outlined, size: 20),
              activeIcon: Icon(Entypo.game_controller, size: 25),
              backgroundColor: Colors.white),
          BottomNavigationBarItem(
              icon: Icon(AntDesign.appstore_o, size: 25),
              activeIcon: Icon(AntDesign.appstore1, size: 25),
              title: Text('Apps'),
              backgroundColor: Colors.white),
          BottomNavigationBarItem(
              icon: Icon(MaterialCommunityIcons.source_branch, size: 25),
              activeIcon: Icon(MaterialCommunityIcons.source_repository, size: 25),
              label: 'Apps livres',
              backgroundColor: Colors.white),
        ],
        selectedItemColor: currentIndex == 0 || currentIndex == 1
            ? Colors.green
            : Colors.red[600],
        onTap: (index) {
          setState(() {
            currentIndex = index;
            if (index == 0) {
              _tabController = TabController(
                  vsync: this, initialIndex: 0, length: getGameList.length);
            } else if (index == 1) {
              _tabController = TabController(
                  vsync: this, initialIndex: 0, length: appsList.length);
            } else if (index == 2) {
              _tabController = TabController(
                  vsync: this, initialIndex: 0, length: movieList.length);
            }
          });
        },
      ),
    );
  }
}
