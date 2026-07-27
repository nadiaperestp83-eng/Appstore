import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:playstore_flutter/model/PSModel.dart';
import 'package:playstore_flutter/screens/PSDetailScreen.dart';
import 'package:playstore_flutter/utils/AppColors.dart';
import 'package:playstore_flutter/utils/AppWidget.dart';
import 'package:playstore_flutter/utils/PSDataProvider.dart';
import 'package:playstore_flutter/widgets/install_button.dart';

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
  String _searchQuery = '';
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
    if (nearBottom && _visibleCount < _filteredApps.length) {
      setState(() {
        _visibleCount = (_visibleCount + _pageSize).clamp(0, _filteredApps.length);
      });
    }
  }

  List<PSGameModel> get _filteredApps {
    if (_searchQuery.trim().isEmpty) return _allApps;
    final q = _searchQuery.toLowerCase();
    return _allApps.where((a) => (a.title ?? '').toLowerCase().contains(q) || (a.subTitle ?? '').toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Buscar apps livres',
                  prefixIcon: Icon(Icons.search),
                  filled: true,
                  fillColor: appDividerColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                ),
                onChanged: (v) {
                  setState(() {
                    _searchQuery = v;
                    // Nova busca recomeça a paginação do zero.
                    _visibleCount = _pageSize;
                  });
                },
              ),
            ),
            Expanded(
              child: FutureBuilder<List<PSGameModel>>(
                future: _appsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Não foi possível carregar os apps livres agora.', style: secondaryTextStyle()),
                    );
                  }

                  final apps = _filteredApps;
                  if (apps.isEmpty) {
                    return Center(child: Text('Nenhum app encontrado.', style: secondaryTextStyle()));
                  }

                  final visible = apps.take(_visibleCount).toList();
                  final hasMore = _visibleCount < apps.length;

                  return ListView.separated(
                    controller: _scrollController,
                    padding: EdgeInsets.symmetric(vertical: 8),
                    itemCount: visible.length + (hasMore ? 1 : 0),
                    separatorBuilder: (context, index) => Divider(height: 1, indent: 76),
                    itemBuilder: (context, index) {
                      if (index >= visible.length) {
                        // Sentinela no fim da lista: mostra que ainda há mais
                        // itens (também funciona como fallback caso o
                        // usuário chegue ao fim sem disparar o scroll listener).
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                          ),
                        );
                      }
                      return _FreeAppListItem(app: visible[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Linha de lista otimizada: ícone + título + origem + tamanho + instalar.
class _FreeAppListItem extends StatelessWidget {
  final PSGameModel app;

  const _FreeAppListItem({required this.app});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => PSDetailScreen(data: app).launch(context),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            commonCacheImageWidget(app.imgLogo ?? app.imgMain, height: 48, width: 48, fit: BoxFit.cover).cornerRadiusWithClipRRect(10),
            12.width,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(app.title ?? '', style: boldTextStyle(size: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                  2.height,
                  Row(
                    children: [
                      if ((app.subTitle ?? '').isNotEmpty)
                        Flexible(
                          child: Text(app.subTitle!, style: secondaryTextStyle(size: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      if ((app.appSize ?? 0) > 0) Text(' · ${app.appSize!.toStringAsFixed(1)}MB', style: secondaryTextStyle(size: 12)),
                    ],
                  ),
                ],
              ),
            ),
            12.width,
            InstallButton(app: app, size: InstallButtonSize.small),
          ],
        ),
      ),
    );
  }
}
