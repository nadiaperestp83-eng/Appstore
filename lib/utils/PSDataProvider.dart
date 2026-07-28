import 'package:flutter/material.dart';
import 'package:playstore_flutter/model/PSModel.dart';
import 'package:playstore_flutter/utils/PSConstants.dart';
import 'package:playstore_flutter/utils/PSImages.dart';
import 'package:playstore_flutter/services/github_store_engine.dart';
import 'package:playstore_flutter/services/fdroid_store_engine.dart';
import 'package:playstore_flutter/services/aptoide_store_engine.dart';
import 'package:playstore_flutter/models/store_app.dart';
import 'package:playstore_flutter/services/hub_app.dart';
import 'package:playstore_flutter/services/hub_app_merge_engine.dart';

List<PSGameModel> getDiscoverList() {
  List<PSGameModel> list = [];

  list.add(PSGameModel(title: 'UC Mini-Download', appSize: 10.0, imgLogo: 'https://picsum.photos/250?image=9', imgMain: '', rating: 4.0, subTitle: 'Public review - From your library'));
  list.add(PSGameModel(
      title: 'InsTagram', appSize: 10.0, imgLogo: 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e7/Instagram_logo_2016.svg/1200px-Instagram_logo_2016.svg.png', imgMain: '', rating: 4.0, subTitle: 'Public review - From your library'));
  list.add(PSGameModel(title: 'Freecharge&Bills,Mutual Funds,upi', appSize: 10.0, imgLogo: 'https://www.windowslatest.com/wp-content/uploads/2016/07/freecharge.png', imgMain: '', rating: 4.0, subTitle: 'Public review - From your library'));
  list.add(PSGameModel(title: 'Hangouts', appSize: 10.0, imgLogo: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSJINQ79VicBw31VAIwic4P8C-os8yIs_kRng&usqp=CAU', imgMain: '', rating: 4.0, subTitle: 'Public review - From your library'));

  return list;
}

List<PSMyAppsModel> getLibraryList() {
  List<PSMyAppsModel> list = [];
  list.add(PSMyAppsModel(
      appLogo: "https://picsum.photos/250?image=9",
      title: "UC Mini-Download",
      subTitle: "Not installed",
      time: "Used 1 hr.ago",
      appSize: "22 MB",
      upaDteSubtitle: "Update yesterday",
      isUpdate: true,
      information: "Information not provide by developer"));
  list.add(PSMyAppsModel(
      appLogo: "https://www.windowslatest.com/wp-content/uploads/2016/07/freecharge.png",
      title: "Freecharge&Bills,Mutual Funds,upi",
      subTitle: "Not installed",
      time: "Used 1 hr.ago",
      appSize: "22 MB",
      upaDteSubtitle: "Update yesterday",
      information: "We made improvements and squashed bugs so Twitter is even better for you"));
  list.add(PSMyAppsModel(
      appLogo: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQLOkTi21fKxJXCTEppsrIfrVajClBSSMZyFg&usqp=CAU",
      title: "Goibibo",
      subTitle: "Not installed",
      time: "Used 1 hr.ago",
      appSize: "10 MB",
      upaDteSubtitle: "Update 2 days ago",
      information: "You can now set up OneDriver to unlock with your face,if you device supports it."));
  list.add(PSMyAppsModel(
      appLogo: "https://picsum.photos/250?image=9",
      title: "UC Mini-Download",
      subTitle: "Not installed",
      time: "Used 1 hr.ago",
      appSize: "30 MB",
      upaDteSubtitle: "Update yesterday",
      information: "Thanks for Choosing Chrome! This release includes stability and performance improvements."));
  list.add(PSMyAppsModel(
      appLogo: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSJINQ79VicBw31VAIwic4P8C-os8yIs_kRng&usqp=CAU",
      title: "Hangouts",
      subTitle: "Not installed",
      time: "Used 1 hr.ago",
      appSize: "40 MB",
      upaDteSubtitle: "Update 3 days ago",
      information: "Information not provide by developer"));
  list.add(PSMyAppsModel(
      appLogo: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQpMU4t2akPDKYqN87-K_2iGvDON7rh9Kj-6g&usqp=CAU",
      title: "Google Duo",
      subTitle: "Not installed",
      time: "Used 1 hr.ago",
      appSize: "27 MB",
      upaDteSubtitle: "Update 9 day ago ",
      information: "We made improvements and squashed bugs so Twitter is even better for you"));
  return list;
}

List<PSReviews> getReviewList() {
  List<PSReviews> list1 = [];

  list1.add(PSReviews(cirLogo: "N", title: "Nur AniZa Khalid", date: "11/10/20", subTile: "I have the game especially because it is helps you to rack your brain and at the same time have to fun. I rated 4 starts beacuse the ads are annoying."));
  list1.add(PSReviews(cirLogo: "R", title: "Rohit Vijayan", date: "11/14/20", subTile: "What happened to the merge seven game. why is the changed. this is not possible. where is it. I can't see it.. Its replaced with some thing else"));
  list1.add(PSReviews(
      cirLogo: "B",
      title: "Blue Legend",
      date: "11/28/20",
      subTile: "I am a big fan of the many games on here and it dosen't Overheat my phone. The  games are amazing. Kids should really play these  types of games since there are even Puzzle game in it  "));
  return list1;
}

List<PSRadio> getRadioList() {
  List<PSRadio> radioList = [];

  radioList.add(PSRadio(title: 'Sexual Content'));

  radioList.add(PSRadio(title: 'Graphic Violence'));
  radioList.add(PSRadio(title: 'Hateful or abusive content'));
  radioList.add(PSRadio(title: 'Harmful to device or data '));
  radioList.add(PSRadio(title: 'Improper content rating'));
  radioList.add(PSRadio(title: 'Illegal prescription or other drug'));
  radioList.add(PSRadio(title: 'Copycat or impersonation'));
  radioList.add(PSRadio(title: 'Other object'));

  return radioList;
}

List<CategoriesApps> getCategoriesList() {
  List<CategoriesApps> categories = [];

  categories.add(CategoriesApps(name: 'Action', icon: Icons.star));
  categories.add(CategoriesApps(name: 'Adventure', icon: Icons.data_usage_rounded));
  categories.add(CategoriesApps(name: 'Arcade', icon: (Icons.add_comment)));
  categories.add(CategoriesApps(name: 'Board', icon: (Icons.add_circle_outline)));
  categories.add(CategoriesApps(name: 'Card', icon: Icons.credit_card));
  categories.add(CategoriesApps(name: 'Casino', icon: Icons.casino_outlined));
  categories.add(CategoriesApps(name: 'Eduction', icon: Icons.cast));
  categories.add(CategoriesApps(name: 'Music', icon: Icons.music_note_rounded));
  categories.add(CategoriesApps(name: 'Puzzle', icon: Icons.padding));
  categories.add(CategoriesApps(name: 'Racing', icon: Icons.pages));
  categories.add(CategoriesApps(name: 'Role Playing', icon: Icons.local_play_outlined));
  categories.add(CategoriesApps(name: 'Simulation', icon: Icons.circle_notifications));
  categories.add(CategoriesApps(name: 'Sports', icon: Icons.sports));
  categories.add(CategoriesApps(name: 'Strategy', icon: Icons.amp_stories_rounded));
  categories.add(CategoriesApps(name: 'Trivia', icon: Icons.trip_origin));
  categories.add(CategoriesApps(name: 'Word', icon: Icons.work_outline_sharp));
  return categories;
}

List<CategoriesApps> moviesCategoriesApps() {
  List<CategoriesApps> list = [];

  list.add(CategoriesApps(name: 'Action & adventure', icon: Icons.format_paint));
  list.add(CategoriesApps(name: 'Animation', icon: Icons.handyman_rounded));
  list.add(CategoriesApps(name: 'Comedy', icon: Icons.theater_comedy));
  list.add(CategoriesApps(name: 'Documentary', icon: Icons.date_range));
  list.add(CategoriesApps(name: 'Drama', icon: Icons.drafts));
  list.add(CategoriesApps(name: 'Horror', icon: Icons.swap_horizontal_circle_rounded));
  list.add(CategoriesApps(name: 'Indian Cinema', icon: Icons.chat_outlined));
  list.add(CategoriesApps(name: 'Mystery & Suspense', icon: Icons.saved_search));
  list.add(CategoriesApps(name: 'Sci-fi & fantasy', icon: Icons.wysiwyg_outlined));

  return list;
}

List<CategoriesApps> getCategoriesListApp() {
  List<CategoriesApps> categoriesapps = [];

  categoriesapps.add(CategoriesApps(name: 'Art & Design', icon: Icons.design_services));
  categoriesapps.add(CategoriesApps(name: 'Augmented reality', icon: Icons.data_usage_rounded));
  categoriesapps.add(CategoriesApps(name: 'Auto & Vehicles', icon: (Icons.date_range)));
  categoriesapps.add(CategoriesApps(name: 'Beauty', icon: (Icons.add_circle_outline)));
  categoriesapps.add(CategoriesApps(name: 'Books & Reference', icon: Icons.credit_card));
  categoriesapps.add(CategoriesApps(name: 'Beauty', icon: Icons.casino_outlined));
  categoriesapps.add(CategoriesApps(name: 'Books & Reference', icon: Icons.cast));
  categoriesapps.add(CategoriesApps(name: 'Business', icon: Icons.business));
  categoriesapps.add(CategoriesApps(name: 'Comics', icon: Icons.padding));
  categoriesapps.add(CategoriesApps(name: 'Dating', icon: Icons.pages));
  categoriesapps.add(CategoriesApps(name: 'Eduction', icon: Icons.local_play_outlined));
  categoriesapps.add(CategoriesApps(name: 'Events', icon: Icons.circle_notifications));
  categoriesapps.add(CategoriesApps(name: 'Finance', icon: Icons.sports));
  categoriesapps.add(CategoriesApps(name: 'Food & Drink', icon: Icons.amp_stories_rounded));
  categoriesapps.add(CategoriesApps(name: 'Sports', icon: Icons.trip_origin));
  categoriesapps.add(CategoriesApps(name: 'Games', icon: Icons.work_outline_sharp));

  return categoriesapps;
}

List<ReviewModel> getReviewList1() {
  List<ReviewModel> reviewList = [];
  reviewList.add(ReviewModel(img: 'images/cloneApp/playStore/ps_playstore.png', name: 'Align Jacob', date: '21/11/2020', review: Review, rating: 2.0));
  reviewList.add(ReviewModel(img: 'images/cloneApp/playStore/ps_playstore.png', name: 'John Oliver', date: '11/10/2020', review: review1, rating: 4.0));
  reviewList.add(ReviewModel(img: 'images/cloneApp/playStore/ps_playstore.png', name: 'Thomas Harry', date: '15/02/2020', review: Review, rating: 1.0));
  reviewList.add(ReviewModel(img: 'images/cloneApp/playStore/ps_playstore.png', name: 'James Charlie', date: '25/08/2020', review: Review, rating: 5.0));
  reviewList.add(ReviewModel(img: 'images/cloneApp/playStore/ps_playstore.png', name: 'Joseph James', date: '16/06/2020', review: review1, rating: 2.0));
  return reviewList;
}

List<RattingModel> getRatingList() {
  List<RattingModel> ratingList = [];
  ratingList.add(RattingModel(typeRating: 'ALL'));
  ratingList.add(RattingModel(typeRating: 'POSITIVE'));
  ratingList.add(RattingModel(typeRating: 'CRITICAL'));
  ratingList.add(RattingModel(typeRating: '5', star: Icons.star));
  ratingList.add(RattingModel(typeRating: '4', star: Icons.star));
  ratingList.add(RattingModel(typeRating: '3', star: Icons.star));
  ratingList.add(RattingModel(typeRating: '2', star: Icons.star));
  ratingList.add(RattingModel(typeRating: '1', star: Icons.star));

  return ratingList;
}

List<GameModelList> getGameListGame() {
  List<GameModelList> gameList = [];
  gameList.add(GameModelList(img: PS_GameImg1, videoImg: 'assets/images/videoIcon.gif'));
  gameList.add(GameModelList(img: PS_GameImg2));
  gameList.add(GameModelList(img: PS_GameImg3));
  gameList.add(GameModelList(img: PS_GameImg4));
  gameList.add(GameModelList(img: PS_GameImg5));
  gameList.add(GameModelList(img: PS_GameImg6));
  gameList.add(GameModelList(img: PS_GameImg7));
  gameList.add(GameModelList(img: PS_GameImg8));

  return gameList;
}

List<GameModelList> getGameListGame1() {
  List<GameModelList> gameList1 = [];
  gameList1.add(GameModelList(img: PS_GameImg1));
  gameList1.add(GameModelList(img: PS_GameImg2));
  gameList1.add(GameModelList(img: PS_GameImg3));
  gameList1.add(GameModelList(img: PS_GameImg4));
  gameList1.add(GameModelList(img: PS_GameImg5));
  gameList1.add(GameModelList(img: PS_GameImg6));
  gameList1.add(GameModelList(img: PS_GameImg7));
  gameList1.add(GameModelList(img: PS_GameImg8));

  return gameList1;
}

List<GameModelList> getGameListGame2() {
  List<GameModelList> gameList2 = [];
  gameList2.add(GameModelList(img: PS_GameImg1));
  gameList2.add(GameModelList(img: PS_GameImg2));
  gameList2.add(GameModelList(img: PS_GameImg3));
  gameList2.add(GameModelList(img: PS_GameImg4));
  gameList2.add(GameModelList(img: PS_GameImg5));
  gameList2.add(GameModelList(img: PS_GameImg6));
  gameList2.add(GameModelList(img: PS_GameImg7));
  gameList2.add(GameModelList(img: PS_GameImg8));

  return gameList2;
}

List<GameModelList> getGameListGame3() {
  List<GameModelList> gameList3 = [];
  gameList3.add(GameModelList(img: PS_GameImg1));
  gameList3.add(GameModelList(img: PS_GameImg2));
  gameList3.add(GameModelList(img: PS_GameImg3));
  gameList3.add(GameModelList(img: PS_GameImg4));
  gameList3.add(GameModelList(img: PS_GameImg5));
  gameList3.add(GameModelList(img: PS_GameImg6));
  gameList3.add(GameModelList(img: PS_GameImg7));
  gameList3.add(GameModelList(img: PS_GameImg8));
  return gameList3;
}

// =========================================================================
// FUNÇÃO NOVA: busca apps de verdade (GitHub + F-Droid) e converte para
// PSGameModel, pronta pra usar em qualquer tela no lugar das funções
// mockadas acima (getDiscoverList, getGameListGame, etc.).
// =========================================================================

/// Busca os apps reais nas fontes configuradas, agrupa por packageName
/// (o "merge" do HubApp) e converte cada um para PSGameModel, já com a
/// fonte preferida escolhida (maior versionCode, ou a ordem de
/// [preferredRepoOrder] se informada).
/// Busca os apps reais e distribui nas MESMAS seções que a UI já usa
/// (Recommended for you, Educational apps, Music Players, Tools & utilities),
/// como a Play Store faz: em lotes (padrão 20 por seção) para não sobrecarregar
/// a tela. "Premium apps" fica de fora — F-Droid/GitHub são sempre gratuitos
/// e de código aberto, não existe um equivalente real de app pago pra usar ali.
Future<Map<String, List<PSGameModel>>> getRealAppsBySection({
  List<String> githubRepos = const [],
  List<FDroidStoreEngine>? fdroidEngines,
  List<String> preferredRepoOrder = const [],
  int perSectionLimit = 20,
}) async {
  final hubApps = await _fetchAndMergeHubApps(
    githubRepos: githubRepos,
    fdroidEngines: fdroidEngines,
    preferredRepoOrder: preferredRepoOrder,
  );

  const musicKeywords = ['Multimedia', 'Audio', 'Music', 'Video'];
  const educationKeywords = ['Reading', 'Science & Education', 'Education'];
  const toolsKeywords = ['System', 'Internet', 'Development', 'Security', 'Connectivity', 'Navigation', 'Writing'];

  final music = <HubApp>[];
  final education = <HubApp>[];
  final tools = <HubApp>[];
  final recommended = <HubApp>[];

  for (final hub in hubApps) {
    final cats = hub.categories;
    if (cats.any((c) => musicKeywords.contains(c)) && music.length < perSectionLimit) {
      music.add(hub);
    } else if (cats.any((c) => educationKeywords.contains(c)) && education.length < perSectionLimit) {
      education.add(hub);
    } else if (cats.any((c) => toolsKeywords.contains(c)) && tools.length < perSectionLimit) {
      tools.add(hub);
    } else if (recommended.length < perSectionLimit) {
      recommended.add(hub);
    }
  }

  return {
    'Recommended for you': recommended.map(_hubAppToGameModel).toList(),
    'Educational apps': education.map(_hubAppToGameModel).toList(),
    'Music Players': music.map(_hubAppToGameModel).toList(),
    'Tools & utilities': tools.map(_hubAppToGameModel).toList(),
  };
}

Future<List<HubApp>> _fetchAndMergeHubApps({
  List<String> githubRepos = const [],
  List<FDroidStoreEngine>? fdroidEngines,
  List<String> preferredRepoOrder = const [],
}) async {
  final github = GithubStoreEngine();
  final fdroid = fdroidEngines ?? [FDroidStoreEngine()];

  final results = await Future.wait([
    if (githubRepos.isNotEmpty)
      github.fetchLatestApps(githubRepos).catchError((e) {
        // ignore: avoid_print
        print('[getRealAppsBySection] GitHub falhou: $e');
        return [];
      }),
    ...fdroid.map((engine) => engine.fetchApps().catchError((e) {
          // ignore: avoid_print
          print('[getRealAppsBySection] F-Droid (${engine.repoLabel}) falhou: $e');
          return [];
        })),
  ]);

  final allApps = results.expand((r) => r).toList();
  final mergeEngine = HubAppMergeEngine(preferredRepoOrder: preferredRepoOrder);
  return mergeEngine.merge(allApps.cast());
}

/// Alimenta as seções da aba Games usando o Aptoide, buscando dinamicamente
/// pelo NOME de cada categoria (ex: "Suggested for you" -> busca "Suggested
/// for you game"). Não depende de nomes fixos hardcoded.
Future<Map<String, List<PSGameModel>>> getAptoideGamesBySection(
  List<String> sectionNames, {
  int perSectionLimit = 20,
}) async {
  final aptoide = AptoideStoreEngine();

  final results = await Future.wait(
    sectionNames.map((name) async {
      try {
        final apps = await aptoide.searchApps('$name game', limit: perSectionLimit);
        return MapEntry(name, apps);
      } catch (e) {
        // ignore: avoid_print
        print('[getAptoideGamesBySection] "$name" falhou: $e');
        return MapEntry(name, <StoreApp>[]);
      }
    }),
  );

  aptoide.dispose();

  return {
    for (final entry in results) entry.key: entry.value.map(_storeAppToGameModel).toList(),
  };
}

/// Alimenta os carrosséis da aba Apps usando o Aptoide (busca por termo,
/// já que a API deles não tem um dump completo do catálogo como o F-Droid).
Future<Map<String, List<PSGameModel>>> getAptoideAppsBySection({
  int perSectionLimit = 20,
}) async {
  final aptoide = AptoideStoreEngine();

  const sectionQueries = {
    'Recommended for you': 'app',
    'Educational apps': 'education',
    'Music Players': 'music player',
    'Tools & utilities': 'tools utility',
  };

  final results = await Future.wait(
    sectionQueries.entries.map((entry) async {
      try {
        final apps = await aptoide.searchApps(entry.value, limit: perSectionLimit);
        return MapEntry(entry.key, apps);
      } catch (e) {
        // ignore: avoid_print
        print('[getAptoideAppsBySection] "${entry.key}" falhou: $e');
        return MapEntry(entry.key, <StoreApp>[]);
      }
    }),
  );

  aptoide.dispose();

  return {
    for (final entry in results) entry.key: entry.value.map(_storeAppToGameModel).toList(),
  };
}

// =========================================================================
// Seções reais (Aptoide) para as abas "Games" e "Apps".
// Substituem de vez os tabs mockados "Events", "Premium"/"Premium apps" e
// "Editors'Choice"/"Editor's Choice", que não têm equivalente real na API
// do Aptoide (não é scraping de app pago nem existe endpoint de "evento").
// A categoria "Discover recommended games" também some daqui: as seções
// abaixo já cobrem o mesmo papel ("For you"), só que com dados reais.
// =========================================================================

/// Nomes das seções da aba "For you" de Games. Cada nome vira uma busca
/// "<nome> game" no Aptoide (ver [getAptoideGamesBySection]).
const List<String> gamesForYouSectionNames = [
  'Suggested for you',
  'Rule the arcade',
  'New and updated games',
  'Trending now',
];

/// Nomes das categorias (chips) da aba "Top charts" de Games.
const List<String> gamesTopChartsSectionNames = [
  'Top free',
  'Top grossing',
  'Trending',
];

/// Nomes das categorias (chips) da aba "Top Charts" de Apps.
const List<String> appsTopChartsSectionNames = [
  'Top free',
  'New releases',
  'Trending',
];

/// Igual a [getAptoideAppsBySection], mas genérico: recebe a lista de nomes
/// de seção e busca cada um literalmente (sem sufixo fixo), útil para
/// "Top charts" de Apps, onde não faz sentido acrescentar "game" na busca.
Future<Map<String, List<PSGameModel>>> getAptoideAppsCategorySections(
  List<String> sectionNames, {
  int perSectionLimit = 20,
}) async {
  final aptoide = AptoideStoreEngine();

  final results = await Future.wait(
    sectionNames.map((name) async {
      try {
        final apps = await aptoide.searchApps(name, limit: perSectionLimit);
        return MapEntry(name, apps);
      } catch (e) {
        // ignore: avoid_print
        print('[getAptoideAppsCategorySections] "$name" falhou: $e');
        return MapEntry(name, <StoreApp>[]);
      }
    }),
  );

  aptoide.dispose();

  return {
    for (final entry in results) entry.key: entry.value.map(_storeAppToGameModel).toList(),
  };
}

/// Busca livre no Aptoide (para conectar na barra de busca "Search for apps
/// & games" já existente na tela).
Future<List<PSGameModel>> searchAptoideApps(String query, {int limit = 30}) async {
  final aptoide = AptoideStoreEngine();
  try {
    final apps = await aptoide.searchApps(query, limit: limit);
    return apps.map(_storeAppToGameModel).toList();
  } finally {
    aptoide.dispose();
  }
}

PSGameModel _storeAppToGameModel(StoreApp app) {
  return PSGameModel(
    title: app.title,
    subTitle: app.description,
    imgLogo: app.iconUrl,
    imgMain: app.iconUrl,
    appSize: app.sizeBytes > 0 ? app.sizeBytes / (1024 * 1024) : 0,
    rating: app.ratingAvg ?? 0,
    packageName: app.packageName,
    downloadUrl: app.downloadUrl,
    version: app.version,
    versionCode: app.versionCode,
    preferredRepoLabel: app.repoLabel,
    developer: app.developer,
    downloads: app.downloads,
    description: app.description,
    categories: app.categories,
    availableSourceOptions: [
      PSAppSourceOption(
        repoLabel: app.repoLabel,
        version: app.version,
        downloadUrl: app.downloadUrl,
        source: app.source,
      ),
    ],
  );
}

/// Usado pela aba "Apps livres": busca tudo (F-Droid + GitHub) em uma lista só.
Future<List<PSGameModel>> getRealAppsList({
  List<String> githubRepos = const [],
  List<FDroidStoreEngine>? fdroidEngines,
  List<String> preferredRepoOrder = const [],
}) async {
  final hubApps = await _fetchAndMergeHubApps(
    githubRepos: githubRepos,
    fdroidEngines: fdroidEngines,
    preferredRepoOrder: preferredRepoOrder,
  );
  return hubApps.map(_hubAppToGameModel).toList();
}

/// Busca por texto dentro do catálogo de "Apps livres" (F-Droid + GitHub).
///
/// Usada pela barra de busca global (ver [AppScreen] em
/// PSNavigationScreen.dart) para que o texto digitado no topo filtre tanto
/// os apps "principais" (Aptoide, via [searchAptoideApps]) quanto os apps
/// livres - antes só a Aptoide era pesquisada e a aba "Apps livres" não
/// aparecia em nenhuma busca depois que a barra interna dela foi removida.
///
/// F-Droid/GitHub não expõem um endpoint de busca por texto como a Aptoide,
/// então a filtragem é feita em cima da lista completa já buscada por
/// [getRealAppsList] - mesmo critério (título/descrição) que a aba "Apps
/// livres" usava na sua própria busca antes de ser unificada com a de cima.
Future<List<PSGameModel>> searchFreeApps(
  String query, {
  int limit = 30,
  List<String> githubRepos = const [],
}) async {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return [];

  final allApps = await getRealAppsList(githubRepos: githubRepos);
  final matches = allApps.where((app) {
    final title = (app.title ?? '').toLowerCase();
    final subtitle = (app.subTitle ?? '').toLowerCase();
    return title.contains(q) || subtitle.contains(q);
  }).toList();

  return matches.take(limit).toList();
}

PSGameModel _hubAppToGameModel(HubApp hubApp) {
  final preferred = hubApp.preferredSource;
  return PSGameModel(
    title: hubApp.title,
    subTitle: hubApp.description,
    imgLogo: preferred.iconUrl,
    imgMain: preferred.iconUrl,
    appSize: 0,
    rating: 0,
    packageName: hubApp.packageName,
    downloadUrl: preferred.downloadUrl,
    version: preferred.version,
    versionCode: preferred.versionCode,
    preferredRepoLabel: preferred.repoLabel,
    description: hubApp.description,
    categories: hubApp.categories,
    availableSourceOptions: hubApp.availableSources
        .map((s) => PSAppSourceOption(
              repoLabel: s.repoLabel,
              version: s.version,
              downloadUrl: s.downloadUrl,
              source: s.source,
            ))
        .toList(),
  );
}

/// Usado pela aba "Updates" (My apps & games) pra saber, de cada app REAL
/// instalado no aparelho, se existe uma versão mais nova no nosso catálogo
/// (F-Droid + GitHub). Só conseguimos detectar atualização pra pacotes que
/// batem exatamente com algo do nosso catálogo - apps vindos da Play Store
/// ou de outras lojas não têm como ser comparados (não temos acesso ao
/// catálogo delas), então simplesmente não aparecem como "com atualização".
Future<Map<String, PSGameModel>> getCatalogByPackageName({
  List<String> githubRepos = const [],
  List<String> preferredRepoOrder = const [],
}) async {
  final hubApps = await _fetchAndMergeHubApps(githubRepos: githubRepos, preferredRepoOrder: preferredRepoOrder);
  final map = <String, PSGameModel>{};
  for (final hub in hubApps) {
    if (hub.packageName.isEmpty) continue;
    map[hub.packageName] = _hubAppToGameModel(hub);
  }
  return map;
}
