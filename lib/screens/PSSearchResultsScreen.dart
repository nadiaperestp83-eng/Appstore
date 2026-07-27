import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:playstore_flutter/components/PSAppsForYouComponent.dart';
import 'package:playstore_flutter/model/PSModel.dart';
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

          return GridView.builder(
            padding: EdgeInsets.all(12),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.85,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: results.length,
            itemBuilder: (context, index) {
              return PSAppsForYouComponent(results[index]);
            },
          );
        },
      ),
    );
  }
}
