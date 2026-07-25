class StoreApp {
  final String id;
  final String title;
  final String version;
  final String iconUrl;
  final String downloadUrl;
  final String description;
  final String source; // 'github' ou 'fdroid'

  StoreApp({
    required this.id,
    required this.title,
    required this.version,
    required this.iconUrl,
    required this.downloadUrl,
    required this.description,
    required this.source,
  });

  @override
  String toString() => 'StoreApp($source: $title v$version)';
}
