import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:playstore_flutter/screens/PSAppsGamesScreen.dart';
import 'package:playstore_flutter/screens/PSNotificationScreen.dart';
import 'package:playstore_flutter/screens/PSPlayProtectScreen.dart';
import 'package:playstore_flutter/screens/PSSettingScreen.dart';
import 'package:playstore_flutter/utils/AppleColors.dart';

/// Sheet estilo iOS que substitui o antigo Drawer lateral.
///
/// Chame [showAppleProfileMenuSheet] a partir do botão de perfil no topo
/// (ver [AppScreen] em PSNavigationScreen.dart). Sobe de baixo pra cima,
/// ocupa ~78% da tela, cantos superiores arredondados, fundo cinza claro
/// com cards brancos agrupados - mesmo padrão visual da aba Settings.
Future<void> showAppleProfileMenuSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) => const _ProfileMenuSheet(),
  );
}

class _ProfileMenuSheet extends StatelessWidget {
  const _ProfileMenuSheet();

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme)),
      child: SafeArea(
        child: Container(
          height: MediaQuery.of(context).size.height * 0.78,
          decoration: BoxDecoration(
            color: AppleColors.backgroundSecondary,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              12.height,
              Container(height: 4, width: 36, decoration: BoxDecoration(color: AppleColors.divider, borderRadius: BorderRadius.circular(2))),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _groupedCard([
                        _row(
                          icon: MaterialCommunityIcons.apps_box,
                          title: 'My apps & games',
                          onTap: () {
                            Navigator.pop(context);
                            PSAppsGamesScreen().launch(context);
                          },
                        ),
                        _divider(),
                        _row(
                          icon: AntDesign.bells,
                          title: 'Notifications',
                          onTap: () {
                            Navigator.pop(context);
                            PSNotificationScreen().launch(context);
                          },
                        ),
                      ]),
                      16.height,
                      _groupedCard([
                        _row(
                          icon: MaterialCommunityIcons.security,
                          title: 'Play Protect',
                          onTap: () {
                            Navigator.pop(context);
                            PSPlayProtectScreen().launch(context);
                          },
                        ),
                        _divider(),
                        _row(
                          icon: Icons.settings_outlined,
                          title: 'Settings',
                          onTap: () {
                            Navigator.pop(context);
                            PSSettingScreen().launch(context);
                          },
                        ),
                      ]),
                      24.height,
                      _sectionLabel('REDEEM'),
                      8.height,
                      _groupedCard([
                        _row(icon: Icons.card_giftcard_outlined, title: 'Redeem', onTap: null, showChevron: false),
                      ]),
                      24.height,
                      _sectionLabel('ABOUT'),
                      8.height,
                      _groupedCard([
                        _row(icon: Icons.help_outline_rounded, title: 'Help & feedback', onTap: null, showChevron: false),
                        _divider(),
                        _row(icon: Icons.info_outline_rounded, title: 'About App', onTap: null, showChevron: false),
                      ]),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Building blocks (mesmo padrão visual da aba Settings)
  // ---------------------------------------------------------------------

  Widget _sectionLabel(String text) {
    return Padding(
      padding: EdgeInsets.only(left: 4),
      child: Text(text, style: GoogleFonts.inter(color: AppleColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.4)),
    );
  }

  Widget _groupedCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(color: AppleColors.background, borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }

  Widget _divider() => Divider(height: 1, thickness: 1, color: AppleColors.divider, indent: 52);

  Widget _row({
    required IconData icon,
    required String title,
    required VoidCallback? onTap,
    bool showChevron = true,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppleColors.textSecondary),
            16.width,
            Text(title, style: GoogleFonts.inter(color: AppleColors.textPrimary, fontSize: 15.5)).expand(),
            if (showChevron) Icon(Icons.chevron_right_rounded, color: AppleColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}
