import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:playstore_flutter/model/PSAppbarModel.dart';
import 'package:playstore_flutter/screens/PSAppsScreen.dart';
import 'package:playstore_flutter/screens/PSFreeAppsScreen.dart';
import 'package:playstore_flutter/screens/PSGamesScreen.dart';
import 'package:playstore_flutter/screens/PSNavigationScreen.dart';
import 'package:playstore_flutter/utils/AppleColors.dart';
import 'package:playstore_flutter/utils/PSColor.dart';

class PSDashboardScreen extends StatefulWidget {
  static String tag = '/PSDashboardScreen';

  @override
  PSDashboardScreenState createState() => PSDashboardScreenState();
}

class PSDashboardScreenState extends State<PSDashboardScreen>
    with TickerProviderStateMixin {
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
      backgroundColor: AppleColors.backgroundSecondary,
      extendBody: true,
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
      // O Drawer lateral saiu daqui - o botão de perfil no topo (dentro de
      // AppScreen, em PSNavigationScreen.dart) agora abre um bottom sheet
      // estilo iOS (ver AppleProfileMenuSheet.dart) com os mesmos itens
      // que ficavam aqui.
      bottomNavigationBar: _buildAppleFloatingPillNavBar(),
    );
  }

  void _onNavItemTap(int index) {
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
  }

  /// Barra inferior no estilo da App Store da Apple: uma "pílula" flutuante,
  /// centralizada, com fundo translúcido (blur) e sombra suave - ao invés de
  /// uma BottomNavigationBar tradicional ocupando a largura inteira da tela.
  ///
  /// Apenas 3 abas, na ordem: Games -> Apps -> Apps livres.
  /// (Os equivalentes de "Today", "Arcade" e a lupa de busca separada da
  /// referência da Apple foram propositalmente omitidos.)
  Widget _buildAppleFloatingPillNavBar() {
    final bottomSafeArea = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 44,
        right: 44,
        bottom: bottomSafeArea > 0 ? bottomSafeArea - 4 : 16,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: AppleColors.background.withOpacity(0.72),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: Colors.white.withOpacity(0.4),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _AppleNavItem(
                  label: 'Games',
                  icon: CupertinoIcons.rocket,
                  activeIcon: CupertinoIcons.rocket_fill,
                  isSelected: currentIndex == 0,
                  onTap: () => _onNavItemTap(0),
                ),
                _AppleNavItem(
                  label: 'Apps',
                  icon: CupertinoIcons.square_stack_3d_up,
                  activeIcon: CupertinoIcons.square_stack_3d_up_fill,
                  isSelected: currentIndex == 1,
                  onTap: () => _onNavItemTap(1),
                ),
                _AppleNavItem(
                  label: 'Apps livres',
                  icon: CupertinoIcons.cube,
                  activeIcon: CupertinoIcons.cube_fill,
                  isSelected: currentIndex == 2,
                  onTap: () => _onNavItemTap(2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Item individual da pílula de navegação, no estilo da App Store: ícone
/// Cupertino em cima, rótulo pequeno embaixo. Azul (`AppleColors.accentBlue`)
/// quando selecionado, cinza secundário (`AppleColors.textSecondary`) quando
/// não selecionado.
class _AppleNavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final bool isSelected;
  final VoidCallback onTap;

  const _AppleNavItem({
    Key? key,
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color =
        isSelected ? AppleColors.accentBlue : AppleColors.textSecondary;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedSwitcher(
          duration: Duration(milliseconds: 150),
          child: Column(
            key: ValueKey(isSelected),
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                color: color,
                size: 24,
              ),
              SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
