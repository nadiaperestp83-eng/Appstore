const PSAppName = 'Zircon';

const Review =
    'By keeping all these questions in our mind today we have come up with a new topic called “A Guide on Paragraph Writing”. With this guide, we’ll '
    'try to answer all these questions about paragraph writing. Paragraphs act as the main role in a student’s life. While writing any topic in an'
    ' exam or competition needs paras to explain the concept in an understandable way for the readers';
const review1 =
    "I am a big fan of the many games on here and it dosen't Overheat my phone. The  games are amazing. Kids should really play these  types of games since there are even Puzzle game in it  ";

const isDarkModeOnPref = "isDarkModeOnPref";

/// 'light', 'dark' ou 'system' - controla como [isDarkModeOnPref] deve ser
/// resolvido na próxima abertura do app (ver main.dart).
const themeModePref = "themeModePref";

/// Código do idioma selecionado em Settings > App Language (ex: 'en', 'pt').
const appLanguagePref = "appLanguagePref";

/// Histórico local de buscas (JSON), usado por Settings > Clear Local Search.
const searchHistoryPref = "searchHistoryPref";

/// true depois que o usuário passa pela tela de Boas-vindas + Permissões
/// pela primeira vez (ver PSSplashScreen/PSWelcomeScreen/PSPermissionsScreen).
/// Enquanto for false, todo "abrir app" volta pra esse fluxo de onboarding
/// em vez de ir direto pro Dashboard.
const hasCompletedOnboardingPref = "hasCompletedOnboardingPref";

/// true/false do interruptor "App Protect" (Settings > App Protect) - ver
/// AppProtectService.dart. Ligado por padrão.
const appProtectEnabledPref = "appProtectEnabledPref";

/// Histórico (JSON) das últimas verificações reais do App Protect, pra
/// tela de App Protect mostrar "verificado recentemente" com dado de
/// verdade em vez de mockado.
const appProtectScanHistoryPref = "appProtectScanHistoryPref";


const maxItemCount = 20;

const baseUrl = "https://assets.iqonic.design/old-themeforest-images/Mimik";
