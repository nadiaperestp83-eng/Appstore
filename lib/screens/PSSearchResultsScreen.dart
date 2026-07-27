import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:playstore_flutter/model/PSModel.dart';
import 'package:playstore_flutter/screens/PSDetailScreen.dart';
import 'package:playstore_flutter/utils/AppWidget.dart';
import 'package:playstore_flutter/utils/PSDataProvider.dart';

class PSSearchResultsScreen extends StatefulWidget {
  static String tag = '/PSSearchResultsScreen';
  final String query;

  PSSearchResultsScreen({required this.query});

  @override
  PSSearchResultsScreenState createState() => PSSearchResultsScreenState();
}

class PSSearchResultsScreenState extends State<PSSearchResultsScreen> {
  late Future<List<PSGameModel>> _resultsFuture;

  @override
  void initState() {
    super.initState();
    _resultsFuture = searchAptoideApps(widget.query, limit: 30);
  }

  String _formatDownloads(int downloads) {
    if (downloads >= 1000000000) return '${(downloads / 1000000000).toStringAsFixed(1)}B+';
    if (downloads >= 1000000) return '${(downloads / 1000000).toStringAsFixed(1)}M+';
    if (downloads >= 1000) return '${(downloads / 1000).toStringAsFixed(1)}K+';
    return '$downloads+';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
        title: Text('Resultados para "${widget.query}"', style: boldTextStyle(color: Colors.black, size: 16)),
      ),
      body: FutureBuilder<List<PSGameModel>>(
        future: _resultsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Não foi possível buscar agora.', style: secondaryTextStyle()));
          }

          final results = snapshot.data ?? [];
          if (results.isEmpty) {
            return Center(child: Text('Nenhum resultado para "${widget.query}".', style: secondaryTextStyle()));
          }

          return ListView.separated(
            padding: EdgeInsets.symmetric(vertical: 8),
            itemCount: results.length,
            separatorBuilder: (_, __) => Divider(height: 1, indent: 16, endIndent: 16),
            itemBuilder: (context, index) {
              final app = results[index];
              return _SearchResultTile(app: app);
            },
          );
        },
      ),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  final PSGameModel app;

  const _SearchResultTile({required this.app});

  String _formatDownloads(int downloads) {
    if (downloads >= 1000000000) return '${(downloads / 1000000000).toStringAsFixed(1)}B+';
    if (downloads >= 1000000) return '${(downloads / 1000000).toStringAsFixed(1)}M+';
    if (downloads >= 1000) return '${(downloads / 1000).toStringAsFixed(1)}K+';
    if (downloads > 0) return '$downloads+';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final rating = app.rating ?? 0;
    final sizeMb = app.appSize ?? 0;
    final downloadsText = _formatDownloads(app.downloads ?? 0);

    return InkWell(
      onTap: () {
        PSDetailScreen(data: app).launch(context);
      },
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ícone à esquerda
            commonCacheImageWidget(app.imgLogo, height: 56, width: 56, fit: BoxFit.cover).cornerRadiusWithClipRRect(12),
            12.width,
            // Nome, desenvolvedor, estrelas, tamanho, downloads
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    app.title ?? '',
                    style: boldTextStyle(size: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Desenvolvedor (a API do Aptoide não retorna categoria
                  // no endpoint de busca, então mostramos o desenvolvedor aqui)
                  if ((app.developer ?? '').isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Text(
                        app.developer!,
                        style: secondaryTextStyle(size: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  6.height,
                  Row(
                    children: [
                      if (rating > 0) ...[
                        Icon(Icons.star, size: 13, color: Colors.black54),
                        2.width,
                        Text(rating.toStringAsFixed(1), style: secondaryTextStyle(size: 12)),
                        10.width,
                      ],
                      if (sizeMb > 0) ...[
                        Text('${sizeMb.toStringAsFixed(1)}MB', style: secondaryTextStyle(size: 12)),
                        10.width,
                      ],
                      if (downloadsText.isNotEmpty)
                        Expanded(
                          child: Text(
                            downloadsText,
                            style: secondaryTextStyle(size: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            8.width,
            // Botão de ação lateral (menu expansível, ainda sem ação própria)
            IconButton(
              icon: Icon(Icons.expand_more, color: Colors.black54),
              onPressed: () {
                PSDetailScreen(data: app).launch(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
