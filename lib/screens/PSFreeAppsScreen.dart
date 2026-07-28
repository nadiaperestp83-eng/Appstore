import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:playstore_flutter/components/apple/AppleAppListTile.dart';
import 'package:playstore_flutter/model/PSModel.dart';
import 'package:playstore_flutter/utils/AppleColors.dart';
import 'package:playstore_flutter/utils/PSDataProvider.dart';

/// Aba "Apps livres": apps de código aberto vindos do F-Droid + GitHub.
/// Para adicionar repositórios do GitHub, preencha _githubRepos abaixo,
/// ex: ['Genymobile/scrcpy', 'termux/termux-app'].
///
/// Layout em LISTA (não mais grid) e carregamento progressivo em lotes de
/// 10 itens: a busca na rede continua trazendo a lista inteira de uma vez
/// (é isso que F-Droid/GitHub retornam), mas a tela só CONSTRÓI e RENDERIZA
/// os primeiros 10 itens; o restante só entra conforme o usuário rola até
/// perto do fim. Isso evita a trava visual de tentar montar centenas de
/// linhas (com imagem de rede cada uma) de uma vez só.
///
/// Sem busca própria: a busca global já fica no topo da tela principal
/// (ver [AppScreen] em PSNavigationScreen.dart), então essa aba não duplica
/// uma segunda barra de pesquisa interna.
class PSFreeAppsScreen extends StatefulWidget {
  static String tag = '/PSFreeAppsScreen';

  @override
  PSFreeAppsScreenState createState() => PSFreeAppsScreenState();
}

const int _pageSize = 10;

class PSFreeAppsScreenState extends State<PSFreeAppsScreen> {
  static const List<String> _githubRepos = [];

  late final Future<List<PSGameModel>> _appsFuture;
  final ScrollController _scrollController = ScrollController();

  List<PSGameModel> _allApps = [];
  int _visibleCount = _pageSize;

  @override
  void initState() {
    super.initState();
    _appsFuture = getRealAppsList(githubRepos: _githubRepos).then((apps) {
      _allApps = apps;
      return apps;
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final nearBottom = _scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300;
    if (nearBottom && _visibleCount < _allApps.length) {
      setState(() {
        _visibleCount = (_visibleCount + _pageSize).clamp(0, _allApps.length);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppleColors.background,
      child: SafeArea(
        child: FutureBuilder<List<PSGameModel>>(
          future: _appsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text('Não foi possível carregar os apps livres agora.', style: secondaryTextStyle(color: AppleColors.textSecondary)),
              );
            }

            final apps = _allApps;
            if (apps.isEmpty) {
              return Center(child: Text('Nenhum app encontrado.', style: secondaryTextStyle(color: AppleColors.textSecondary)));
            }

            final visible = apps.take(_visibleCount).toList();
            final hasMore = _visibleCount < apps.length;

            return ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.symmetric(vertical: 8),
              itemCount: visible.length + (hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= visible.length) {
                  // Sentinela no fim da lista: mostra que ainda há mais
                  // itens (também funciona como fallback caso o usuário
                  // chegue ao fim sem disparar o scroll listener).
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                  );
                }
                // Mesmo tile Apple-style (ícone squircle, expansão inline ao
                // toque) usado nas abas Apps e Games - nada de navegação pra
                // tela separada aqui também.
                return AppleAppListTile(data: visible[index]);
              },
            );
          },
        ),
      ),
    );
  }
}
