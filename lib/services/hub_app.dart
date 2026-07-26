import '../models/store_app.dart';

/// Representa UMA fonte disponível pra um app agrupado (HubApp).
/// Cada StoreApp original vira uma AppSourceOption dentro do HubApp.
class AppSourceOption {
  final String sourceId; // identificador único da fonte (ex: repoLabel + versão)
  final String repoLabel; // nome amigável (ex: "F-Droid oficial", "GitHub: dono/repo")
  final String source; // 'github' ou 'fdroid'
  final String version;
  final int versionCode;
  final String downloadUrl; // link direto do .apk, sem zip
  final String iconUrl;
  final String description;
  final List<String> categories;

  AppSourceOption({
    required this.sourceId,
    required this.repoLabel,
    required this.source,
    required this.version,
    required this.versionCode,
    required this.downloadUrl,
    required this.iconUrl,
    required this.description,
    this.categories = const [],
  });

  factory AppSourceOption.fromStoreApp(StoreApp app) {
    return AppSourceOption(
      sourceId: '${app.repoLabel}::${app.version}',
      repoLabel: app.repoLabel.isEmpty ? app.source : app.repoLabel,
      source: app.source,
      version: app.version,
      versionCode: app.versionCode,
      downloadUrl: app.downloadUrl,
      iconUrl: app.iconUrl,
      description: app.description,
      categories: app.categories,
    );
  }
}

/// Item único exibido na UI, mesmo quando o mesmo pacote existe em várias
/// fontes (ex: F-Droid oficial + um repo customizado). Agrupa todas as
/// fontes em [availableSources] e resolve qual delas mostrar por padrão.
class HubApp {
  final String packageName; // chave de agrupamento (ex: org.telegram.messenger)
  final String title;
  final String description;
  final List<AppSourceOption> availableSources;
  final List<String> categories; // união das categorias de todas as fontes

  /// sourceId escolhido para exibir/baixar. Pode ser sobrescrito pelo
  /// usuário na tela de detalhes (ver seletor "Disponível em N fontes").
  String preferredSourceId;

  HubApp({
    required this.packageName,
    required this.title,
    required this.description,
    required this.availableSources,
    List<String>? categories,
    String? preferredSourceId,
  })  : categories = categories ?? availableSources.expand((s) => s.categories).toSet().toList(),
        preferredSourceId = preferredSourceId ?? _pickDefault(availableSources).sourceId;

  bool get hasMultipleSources => availableSources.length > 1;

  AppSourceOption get preferredSource => availableSources.firstWhere(
        (s) => s.sourceId == preferredSourceId,
        orElse: () => availableSources.first,
      );

  /// Escolhe a fonte padrão: maior versionCode primeiro; em empate
  /// (ex: dois releases do GitHub sem versionCode conhecido, ambos 0),
  /// mantém a primeira encontrada.
  static AppSourceOption _pickDefault(List<AppSourceOption> sources) {
    final sorted = [...sources]..sort((a, b) => b.versionCode.compareTo(a.versionCode));
    return sorted.first;
  }

  /// Permite ao usuário trocar manualmente a fonte preferida (ex: ao tocar
  /// no seletor "Disponível em 2 fontes" na tela de detalhes).
  void selectSource(String sourceId) {
    final exists = availableSources.any((s) => s.sourceId == sourceId);
    if (exists) preferredSourceId = sourceId;
  }
}
