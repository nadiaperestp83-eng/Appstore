import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:playstore_flutter/components/PSAppsForYouComponent.dart';
import 'package:playstore_flutter/model/PSModel.dart';
import 'package:playstore_flutter/utils/PSColor.dart';
import 'package:playstore_flutter/utils/PSDataProvider.dart';

/// Aba "Apps livres": apps de código aberto vindos do F-Droid + GitHub.
/// Para adicionar repositórios do GitHub, preencha _githubRepos abaixo,
/// ex: ['Genymobile/scrcpy', 'termux/termux-app'].
class PSFreeAppsScreen extends StatefulWidget {
  static String tag = '/PSFreeAppsScreen';

  @override
  PSFreeAppsScreenState createState() => PSFreeAppsScreenState();
}

class PSFreeAppsScreenState extends State<PSFreeAppsScreen> {
  static const List<String> _githubRepos = [];

  late Future<List<PSGameModel>> _appsFuture;
  List<PSGameModel> _allApps = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _appsFuture = getRealAppsList(githubRepos: _githubRepos).then((apps) {
      _allApps = apps;
      return apps;
    });
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

                  return GridView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: apps.length,
                    itemBuilder: (context, index) {
                      return PSAppsForYouComponent(apps[index]);
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
