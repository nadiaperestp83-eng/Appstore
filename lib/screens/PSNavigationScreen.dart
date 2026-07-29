import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:playstore_flutter/components/apple/AppleProfileMenuSheet.dart';
import 'package:playstore_flutter/screens/PSSearchResultsScreen.dart';
import 'package:playstore_flutter/utils/AppleColors.dart';
import 'package:playstore_flutter/utils/PSSearchHistoryUtil.dart';

class AppScreen extends StatefulWidget {
  static String tag = '/AppScreen';

  @override
  AppScreenState createState() => AppScreenState();
}

class AppScreenState extends State<AppScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    init();
  }

  init() async {
    //
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _runSearch(BuildContext context) {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    PSSearchHistory.add(query);
    PSSearchResultsScreen(query: query).launch(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(right: 8),
      alignment: Alignment.topCenter,
      decoration: BoxDecoration(
        color: AppleColors.background,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
        borderRadius: BorderRadius.circular(12),
      ),
      width: MediaQuery.of(context).size.width,
      margin: EdgeInsets.only(top: 50, left: 16, right: 16),
      child: Row(
        children: [
          12.width,
          TextFormField(
            controller: _searchController,
            showCursor: true,
            textInputAction: TextInputAction.search,
            onFieldSubmitted: (_) => _runSearch(context),
            style: primaryTextStyle(color: AppleColors.textPrimary),
            decoration: InputDecoration(
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              hintText: 'Search for apps & games',
              hintStyle: secondaryTextStyle(color: AppleColors.textSecondary),
            ),
          ).expand(),
          IconButton(
            icon: Icon(Icons.search, color: AppleColors.textSecondary),
            onPressed: () => _runSearch(context),
          ),
          IconButton(
            icon: Icon(Icons.keyboard_voice_outlined, color: AppleColors.textSecondary),
            onPressed: () {},
          ),
          // Botão de perfil: antes abria o Drawer lateral (junto com o
          // ícone de hambúrguer que ficava aqui do lado); agora ele
          // sozinho abre o sheet estilo iOS que sobe de baixo pra cima
          // (ver AppleProfileMenuSheet.dart) - não existe mais Drawer no
          // app.
          InkWell(
            onTap: () => showAppleProfileMenuSheet(context),
            child: CircleAvatar(
              maxRadius: 17,
              backgroundColor: AppleColors.backgroundSecondary,
              child: Icon(Icons.person_rounded, color: AppleColors.textSecondary, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
