import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:playstore_flutter/components/apple/AppleProfileMenuSheet.dart';
import 'package:playstore_flutter/screens/PSSearchResultsScreen.dart';
import 'package:playstore_flutter/utils/AppleColors.dart';
import 'package:playstore_flutter/utils/PSSearchHistoryUtil.dart';

/// Cabeçalho estilo iOS: título grande da seção à esquerda ("Games" /
/// "Apps" / "Apps livres", conforme a aba ativa) e um pequeno grupo de
/// ícones de ação à direita (busca, microfone, configurações).
///
/// Substitui a antiga barra de busca flutuante gigante que ficava aqui -
/// agora a busca abre em cima da tela (via [showSearch]/[_AppSearchDelegate])
/// só quando o usuário toca na lupa, e a engrenagem abre o menu estilo
/// iOS ([showAppleProfileMenuSheet]) que era o antigo Drawer/hambúrguer.
class AppScreen extends StatefulWidget {
  static String tag = '/AppScreen';

  /// Título grande exibido à esquerda (ex: "Games", "Apps", "Apps livres").
  final String title;

  const AppScreen({Key? key, required this.title}) : super(key: key);

  @override
  AppScreenState createState() => AppScreenState();
}

class AppScreenState extends State<AppScreen> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppleColors.background,
      padding: EdgeInsets.only(top: 50, left: 16, right: 8, bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              widget.title,
              style: boldTextStyle(color: AppleColors.textPrimary, size: 30),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: Icon(Icons.search, color: AppleColors.textSecondary),
            onPressed: () => _openSearch(context),
          ),
          IconButton(
            icon: Icon(Icons.keyboard_voice_outlined, color: AppleColors.textSecondary),
            onPressed: () {},
          ),
          // Engrenagem no lugar do antigo avatar de perfil: abre o mesmo
          // menu que o antigo hambúrguer abria (agora um bottom sheet
          // estilo iOS - ver AppleProfileMenuSheet.dart), não a tela de
          // Settings direto. "Settings" é só um dos itens dentro do menu.
          IconButton(
            icon: Icon(Icons.settings, color: AppleColors.textSecondary),
            onPressed: () => showAppleProfileMenuSheet(context),
          ),
        ],
      ),
    );
  }

  void _openSearch(BuildContext context) async {
    final query = await showSearch<String?>(
      context: context,
      delegate: _AppSearchDelegate(),
    );
    if (query != null && query.trim().isNotEmpty) {
      PSSearchHistory.add(query.trim());
      PSSearchResultsScreen(query: query.trim()).launch(context);
    }
  }
}

/// Delegate de busca padrão do Flutter (abre em cima da tela, com o
/// teclado já focado). Sugestões mostram o histórico local salvo em
/// [PSSearchHistory]; tocar em uma sugestão ou apertar "buscar" no
/// teclado fecha esta camada e devolve o texto para [AppScreenState].
class _AppSearchDelegate extends SearchDelegate<String?> {
  @override
  String get searchFieldLabel => 'Search for apps & games';

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: Icon(Icons.clear),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) close(context, query);
    });
    return const SizedBox.shrink();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: PSSearchHistory.getAll(),
      builder: (context, snapshot) {
        final history = snapshot.data ?? [];
        if (history.isEmpty) return const SizedBox.shrink();

        return ListView.builder(
          itemCount: history.length,
          itemBuilder: (context, index) {
            final term = history[index];
            return ListTile(
              leading: Icon(Icons.history, color: AppleColors.textSecondary),
              title: Text(term),
              onTap: () {
                query = term;
                close(context, term);
              },
            );
          },
        );
      },
    );
  }
}
