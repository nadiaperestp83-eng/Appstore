/// Um idioma disponível no seletor de Settings > App Language.
///
/// Só controla qual idioma fica marcado/selecionado por enquanto - a
/// tradução de fato ainda não está implementada (ver comentário em
/// [PSSettingScreen]).
class AppLanguage {
  final String code;
  final String englishName;
  final String nativeName;

  const AppLanguage({required this.code, required this.englishName, required this.nativeName});
}

const List<AppLanguage> kAppLanguages = [
  AppLanguage(code: 'en', englishName: 'English', nativeName: 'English'),
  AppLanguage(code: 'pt', englishName: 'Portuguese', nativeName: 'Português'),
  AppLanguage(code: 'es', englishName: 'Spanish', nativeName: 'Español'),
  AppLanguage(code: 'fr', englishName: 'French', nativeName: 'Français'),
  AppLanguage(code: 'de', englishName: 'German', nativeName: 'Deutsch'),
  AppLanguage(code: 'it', englishName: 'Italian', nativeName: 'Italiano'),
  AppLanguage(code: 'ja', englishName: 'Japanese', nativeName: '日本語'),
  AppLanguage(code: 'ko', englishName: 'Korean', nativeName: '한국어'),
  AppLanguage(code: 'zh', englishName: 'Chinese (Simplified)', nativeName: '简体中文'),
  AppLanguage(code: 'ar', englishName: 'Arabic', nativeName: 'العربية'),
  AppLanguage(code: 'ru', englishName: 'Russian', nativeName: 'Русский'),
  AppLanguage(code: 'hi', englishName: 'Hindi', nativeName: 'हिन्दी'),
];

AppLanguage languageForCode(String code) {
  return kAppLanguages.firstWhere((l) => l.code == code, orElse: () => kAppLanguages.first);
}
