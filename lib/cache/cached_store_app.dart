import 'package:isar_community/isar.dart';
import '../models/store_app.dart';

part 'cached_store_app.g.dart';

@collection
class CachedStoreApp {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String appId; // corresponde a StoreApp.id

  late String title;
  late String version;
  late String iconUrl;
  late String downloadUrl;
  late String description;

  @Index()
  late String source; // 'github' ou 'fdroid'

  late DateTime cachedAt;

  StoreApp toStoreApp() => StoreApp(
        id: appId,
        title: title,
        version: version,
        iconUrl: iconUrl,
        downloadUrl: downloadUrl,
        description: description,
        source: source,
      );

  static CachedStoreApp fromStoreApp(StoreApp app) => CachedStoreApp()
    ..appId = app.id
    ..title = app.title
    ..version = app.version
    ..iconUrl = app.iconUrl
    ..downloadUrl = app.downloadUrl
    ..description = app.description
    ..source = app.source
    ..cachedAt = DateTime.now();
}
