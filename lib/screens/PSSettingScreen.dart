import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:playstore_flutter/main.dart';
import 'package:playstore_flutter/utils/AppLanguages.dart';
import 'package:playstore_flutter/utils/AppleColors.dart';
import 'package:playstore_flutter/utils/PSConstants.dart';
import 'package:playstore_flutter/utils/PSSearchHistoryUtil.dart';

/// Aba Settings, no padrão visual "grouped list" do iOS: rótulo de seção
/// em maiúsculas sobre um card branco arredondado, linhas separadas por
/// divisores finos e recuados (mesmo estilo do print de referência de
/// "Automatic Downloads").
///
/// Contém apenas os 3 itens pedidos:
/// - App Language: abre uma folha (bottom sheet) que sobe de baixo pra
///   cima, seguindo as cores do app, com a lista de idiomas. Só marca o
///   idioma selecionado por enquanto - a tradução de fato do app para
///   esse idioma é um trabalho futuro (ver [AppLanguages]).
/// - Theme: mesma folha, com Light / Dark / System. Já aplica de verdade,
///   ligado ao [AppStore.toggleDarkMode] que o projeto já tinha.
/// - Clear Local Search: apaga o histórico de buscas salvo localmente
///   (ver [PSSearchHistory]) depois de confirmação.
class PSSettingScreen extends StatefulWidget {
  static String tag = '/PSSettingScreen';

  @override
  PSSettingScreenState createState() => PSSettingScreenState();
}

class PSSettingScreenState extends State<PSSettingScreen> {
  String _languageCode = 'en';
  String _themeMode = 'system'; // 'system' | 'light' | 'dark'

  @override
  void initState() {
    super.initState();
    init();
  }

  init() async {
    final code = await getStringAsync(appLanguagePref, defaultValue: appStore.selectedLanguage);
    final mode = await getStringAsync(themeModePref, defaultValue: appStore.isDarkModeOn ? 'dark' : 'light');
    setState(() {
      _languageCode = code.isEmpty ? 'en' : code;
      _themeMode = mode.isEmpty ? 'system' : mode;
    });
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  String get _themeModeLabel {
    switch (_themeMode) {
      case 'dark':
        return 'Dark';
      case 'light':
        return 'Light';
      default:
        return 'System';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      // Tipografia estilo SF Pro/iOS só nesta tela - não mexe no restante
      // do app.
      data: Theme.of(context).copyWith(textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme)),
      child: Scaffold(
        backgroundColor: AppleColors.backgroundSecondary,
        appBar: AppBar(
          backgroundColor: AppleColors.background,
          elevation: 0,
          iconTheme: IconThemeData(color: AppleColors.textPrimary),
          title: Text('Settings', style: GoogleFonts.inter(color: AppleColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w600)),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel('GENERAL'),
              8.height,
              _groupedCard([
                _row(
                  title: 'App Language',
                  value: languageForCode(_languageCode).nativeName,
                  onTap: _openLanguageSheet,
                ),
                _divider(),
                _row(
                  title: 'Theme',
                  value: _themeModeLabel,
                  onTap: _openThemeSheet,
                ),
                _divider(),
                _row(
                  title: 'Clear Local Search',
                  value: '',
                  titleColor: Color(0xFFFF3B30), // vermelho de ação destrutiva, padrão iOS
                  showChevron: false,
                  onTap: _confirmClearSearchHistory,
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Building blocks visuais (card agrupado estilo iOS)
  // ---------------------------------------------------------------------

  Widget _sectionLabel(String text) {
    return Padding(
      padding: EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: GoogleFonts.inter(color: AppleColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.4),
      ),
    );
  }

  Widget _groupedCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(color: AppleColors.background, borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }

  Widget _divider() => Divider(height: 1, thickness: 1, color: AppleColors.divider, indent: 16);

  Widget _row({
    required String title,
    required String value,
    required VoidCallback onTap,
    Color? titleColor,
    bool showChevron = true,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Text(title, style: GoogleFonts.inter(color: titleColor ?? AppleColors.textPrimary, fontSize: 15.5)).expand(),
            if (value.isNotEmpty)
              Text(value, style: GoogleFonts.inter(color: AppleColors.textSecondary, fontSize: 15)),
            if (showChevron) ...[
              4.width,
              Icon(Icons.chevron_right_rounded, color: AppleColors.textSecondary, size: 20),
            ],
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Bottom sheets
  // ---------------------------------------------------------------------

  Future<void> _openLanguageSheet() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => _OptionSheet(
        title: 'App Language',
        maxHeightFraction: 0.65,
        children: kAppLanguages.map((lang) {
          final isSelected = lang.code == _languageCode;
          return _OptionSheetTile(
            title: lang.nativeName,
            subtitle: lang.nativeName == lang.englishName ? null : lang.englishName,
            selected: isSelected,
            onTap: () => Navigator.pop(sheetContext, lang.code),
          );
        }).toList(),
      ),
    );

    if (selected != null && selected != _languageCode) {
      await setValue(appLanguagePref, selected);
      appStore.setLanguage(selected);
      setState(() => _languageCode = selected);
    }
  }

  Future<void> _openThemeSheet() async {
    final options = [
      {'key': 'system', 'label': 'System', 'subtitle': 'Match device setting'},
      {'key': 'light', 'label': 'Light', 'subtitle': null},
      {'key': 'dark', 'label': 'Dark', 'subtitle': null},
    ];

    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => _OptionSheet(
        title: 'Theme',
        maxHeightFraction: 0.4,
        children: options.map((opt) {
          final isSelected = opt['key'] == _themeMode;
          return _OptionSheetTile(
            title: opt['label'] as String,
            subtitle: opt['subtitle'] as String?,
            selected: isSelected,
            onTap: () => Navigator.pop(sheetContext, opt['key'] as String),
          );
        }).toList(),
      ),
    );

    if (selected != null && selected != _themeMode) {
      bool resolvedDark;
      if (selected == 'system') {
        resolvedDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
      } else {
        resolvedDark = selected == 'dark';
      }
      await setValue(themeModePref, selected);
      appStore.toggleDarkMode(value: resolvedDark);
      setState(() => _themeMode = selected);
    }
  }

  Future<void> _confirmClearSearchHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppleColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text('Clear Local Search?', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppleColors.textPrimary)),
        content: Text(
          'This removes the searches you have performed from this device. This can\'t be undone.',
          style: GoogleFonts.inter(color: AppleColors.textSecondary, fontSize: 14),
        ),
        actionsPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: AppleColors.accentBlue)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('Clear', style: GoogleFonts.inter(color: Color(0xFFFF3B30), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await PSSearchHistory.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search history cleared', style: GoogleFonts.inter())),
        );
      }
    }
  }
}

/// Folha (bottom sheet) genérica de seleção única: sobe de baixo pra cima,
/// cantos arredondados, com um "puxador" (drag handle) no topo, seguindo
/// as cores do app ([AppleColors]) e a fonte estilo iOS (Inter).
class _OptionSheet extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final double maxHeightFraction;

  const _OptionSheet({required this.title, required this.children, this.maxHeightFraction = 0.6});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * maxHeightFraction),
        decoration: BoxDecoration(
          color: AppleColors.background,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            12.height,
            Container(height: 4, width: 36, decoration: BoxDecoration(color: AppleColors.divider, borderRadius: BorderRadius.circular(2))),
            16.height,
            Text(title, style: GoogleFonts.inter(color: AppleColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
            8.height,
            Divider(height: 1, thickness: 1, color: AppleColors.divider),
            Flexible(
              child: ListView(shrinkWrap: true, padding: EdgeInsets.zero, children: children),
            ),
            8.height,
          ],
        ),
      ),
    );
  }
}

class _OptionSheetTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _OptionSheetTile({required this.title, required this.selected, required this.onTap, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: GoogleFonts.inter(color: AppleColors.textPrimary, fontSize: 15.5)),
                if (subtitle != null)
                  Text(subtitle!, style: GoogleFonts.inter(color: AppleColors.textSecondary, fontSize: 12)),
              ],
            ).expand(),
            if (selected) Icon(Icons.check_rounded, color: AppleColors.accentBlue, size: 22),
          ],
        ),
      ),
    );
  }
}
