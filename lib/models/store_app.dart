class StoreApp {
  final String id;
  final String title;
  final String version;
  final int versionCode; // usado para ranquear qual fonte é "mais recente"
  final String iconUrl;
  final String downloadUrl;
  final String description;
  final String source; // 'github' ou 'fdroid'
  final String? packageName; // nome real do pacote Android, quando conhecido
  final String repoLabel; // nome amigável do repositório de origem (ex: "F-Droid oficial")

  StoreApp({
    required this.id,
    required this.title,
    required this.version,
    this.versionCode = 0,
    required this.iconUrl,
    required this.downloadUrl,
    required this.description,
    required this.source,
    this.packageName,
    this.repoLabel = '',
  });

  @override
  String toString() => 'StoreApp($source: $title v$version)';
}
