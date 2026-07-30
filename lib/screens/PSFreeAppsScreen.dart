import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:playstore_flutter/components/apple/AppleAppListTile.dart';
import 'package:playstore_flutter/components/apple/AppleGroupedCard.dart';
import 'package:playstore_flutter/model/PSModel.dart';
import 'package:playstore_flutter/utils/AppleColors.dart';
import 'package:playstore_flutter/utils/PSDataProvider.dart';
import 'package:playstore_flutter/services/fdroid_store_engine.dart';

/// Aba "Apps livres": apps de código aberto vindos de várias fontes,
/// somadas (nenhuma substitui a outra):
/// - F-Droid oficial + IzzyOnDroid (repositório F-Droid compatível de
///   terceiros, ~1400 apps extras) - ver [_fdroidEngines] abaixo pra
///   adicionar outros repositórios F-Droid compatíveis.
/// - GitHub: continua 100% independente, alimentado pela lista manual
///   _githubRepos abaixo (igual sempre foi) - ex:
///   ['Genymobile/scrcpy', 'termux/termux-app'].
/// - Codeberg: mesma ideia, lista manual _codebergRepos abaixo.
/// - Obtainium: catálogo comunitário (github/codeberg descobertos por ele -
///   ver ObtainiumCatalogEngine.dart) somado a tudo isso, nunca no lugar.
///
/// Layout em LISTA (não mais grid) e carregamento progressivo em lotes de
/// 10 itens: a busca na rede continua trazendo a lista inteira de uma vez
/// (é isso que F-Droid/Codeberg/GitHub retornam), mas a tela só CONSTRÓI e
/// RENDERIZA os primeiros 10 itens; o restante só entra conforme o usuário
/// rola até perto do fim. Isso evita a trava visual de tentar montar
/// centenas de linhas (com imagem de rede cada uma) de uma vez só.
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
  static const List<String> _codebergRepos = [];

  // F-Droid oficial + IzzyOnDroid por padrão. Pra somar outro repositório
  // F-Droid compatível de terceiros, é só adicionar mais um FDroidStoreEngine
  // aqui (ex: FDroidStoreEngine(repoBaseUrl: '...', repoLabel: '...')).
  static final List<FDroidStoreEngine> _fdroidEngines = [
    FDroidStoreEngine(),
    FDroidStoreEngine(repoBaseUrl: 'https://apt.izzysoft.de/fdroid/repo', repoLabel: 'IzzyOnDroid'),
  ];

  late final Future<List<PSGameModel>> _appsFuture;
  final ScrollController _scrollController = ScrollController();

  List<PSGameModel> _allApps = [];
  int _visibleCount = _pageSize;

  @override
  void initState() {
    super.initState();
    _appsFuture = getRealAppsList(
      githubRepos: _githubRepos,
      codebergRepos: _codebergRepos,
      fdroidEngines: _fdroidEngines,
    ).then((apps) {
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
      color: AppleColors.backgroundSecondary,
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

            // Agrupada em cards brancos de até _pageSize itens (em vez de
            // um único card gigante) - assim cada lote carregado pelo
            // scroll infinito já chega "fechado" visualmente, sem precisar
            // recalcular divisores do card inteiro a cada novo lote.
            final chunkCount = (visible.length / _pageSize).ceil();

            return ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.only(top: 8, bottom: 100),
              itemCount: chunkCount + (hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= chunkCount) {
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

                final start = index * _pageSize;
                final end = (start + _pageSize).clamp(0, visible.length);
                final chunk = visible.sublist(start, end);

                // Mesmo tile Apple-style (ícone squircle, expansão inline ao
                // toque) usado nas abas Apps e Games - nada de navegação pra
                // tela separada aqui também.
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: AppleGroupedCard(
                    dividerIndent: 84,
                    children: chunk.map((app) => AppleAppListTile(data: app)).toList(),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
