import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:playstore_flutter/components/apple/AppleAppListTile.dart';
import 'package:playstore_flutter/model/PSModel.dart';
import 'package:playstore_flutter/utils/AppleColors.dart';
import 'package:playstore_flutter/utils/PSDataProvider.dart';

/// Resultado combinado: a barra de busca global pesquisa nas DUAS fontes
/// que o app conhece - Aptoide ("Apps"/"Games") e F-Droid/GitHub ("Apps
/// livres") - em paralelo, e mostra cada uma em sua própria seção. Antes
/// só a Aptoide era pesquisada aqui; a aba "Apps livres" perdeu sua busca
/// interna e ficaria sem nenhuma forma de busca se esta tela continuasse
/// ignorando aquele catálogo.
class PSSearchResultsScreen extends StatefulWidget {
  static String tag = '/PSSearchResultsScreen';
  final String query;

  PSSearchResultsScreen({required this.query});

  @override
  PSSearchResultsScreenState createState() => PSSearchResultsScreenState();
}

class _CombinedResults {
  final List<PSGameModel> apps;
  final List<PSGameModel> freeApps;

  _CombinedResults({required this.apps, required this.freeApps});

  bool get isEmpty => apps.isEmpty && freeApps.isEmpty;
}

class PSSearchResultsScreenState extends State<PSSearchResultsScreen> {
  late final Future<_CombinedResults> _resultsFuture;

  @override
  void initState() {
    super.initState();
    _resultsFuture = _runCombinedSearch(widget.query);
  }

  /// Dispara as duas buscas em paralelo. Se uma das fontes falhar (ex:
  /// F-Droid fora do ar), a outra ainda aparece normalmente - erro isolado
  /// numa fonte não derruba a busca inteira.
  Future<_CombinedResults> _runCombinedSearch(String query) async {
    final results = await Future.wait([
      searchAptoideApps(query, limit: 30).catchError((_) => <PSGameModel>[]),
      searchFreeApps(query, limit: 30).catchError((_) => <PSGameModel>[]),
    ]);
    return _CombinedResults(apps: results[0], freeApps: results[1]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppleColors.background,
      appBar: AppBar(
        backgroundColor: AppleColors.background,
        elevation: 0,
        iconTheme: IconThemeData(color: AppleColors.textPrimary),
        title: Text(
          'Resultados para "${widget.query}"',
          style: boldTextStyle(color: AppleColors.textPrimary, size: 16),
        ),
      ),
      body: FutureBuilder<_CombinedResults>(
        future: _resultsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Não foi possível buscar agora.', style: secondaryTextStyle(color: AppleColors.textSecondary)));
          }

          final combined = snapshot.data ?? _CombinedResults(apps: [], freeApps: []);
          if (combined.isEmpty) {
            return Center(child: Text('Nenhum resultado para "${widget.query}".', style: secondaryTextStyle(color: AppleColors.textSecondary)));
          }

          return ListView(
            padding: EdgeInsets.symmetric(vertical: 8),
            children: [
              if (combined.apps.isNotEmpty) ..._buildSection('Apps', combined.apps),
              if (combined.freeApps.isNotEmpty) ..._buildSection('Apps livres', combined.freeApps),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildSection(String title, List<PSGameModel> apps) {
    return [
      Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Text(title, style: boldTextStyle(color: AppleColors.textPrimary, size: 18)),
      ),
      ...apps.map((app) => AppleAppListTile(data: app)),
    ];
  }
}
