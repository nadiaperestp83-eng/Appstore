import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:playstore_flutter/screens/PSDashboardScreen.dart';
import 'package:playstore_flutter/screens/PSWelcomeScreen.dart';
import 'package:playstore_flutter/services/obtainium_catalog_engine.dart';
import 'package:playstore_flutter/utils/AppWidget.dart';
import 'package:playstore_flutter/utils/AppleColors.dart';
import 'package:playstore_flutter/utils/PSConstants.dart';

/// Splash.
///
/// - Primeira vez que o app é aberto (`hasCompletedOnboardingPref` ainda
///   não existe): não mostra marca nenhuma aqui - só encaminha
///   imediatamente pro fluxo de onboarding (Boas-vindas -> Permissões). A
///   marca "Zircon Labs" só aparece DEPOIS que esse fluxo termina, exatamente
///   como pedido.
/// - Toda vez depois disso (`hasCompletedOnboardingPref == true`, seja
///   porque acabou de sair de [PSPermissionsScreen] ou porque é uma
///   abertura normal do app): mostra a marca por 2s e segue pro Dashboard.
class PSSplashScreen extends StatefulWidget {
  static String tag = '/PSSplashScreen';

  @override
  PSSplashScreenState createState() => PSSplashScreenState();
}

class PSSplashScreenState extends State<PSSplashScreen> {
  @override
  void initState() {
    super.initState();
    init();
  }

  init() async {
    // Dispara em segundo plano, sem esperar e sem travar o splash: quando
    // o usuário chegar na aba Apps, o catálogo do Obtainium (~230 apps)
    // já deve estar em cache (ver ObtainiumCatalogEngine._cachedCatalog),
    // então "More Apps" carrega na hora em vez de baixar tudo ali.
    ObtainiumCatalogEngine().fetchMoreApps(limit: 1).catchError((e) {
      // ignore: avoid_print
      print('[PSSplashScreen] Pré-aquecimento do catálogo Obtainium falhou (sem problema, tenta de novo na hora certa): $e');
      return <dynamic>[];
    });
    checkFirstSeen();
  }

  Future checkFirstSeen() async {
    final onboardingDone = await getBool(hasCompletedOnboardingPref, defaultValue: false);

    if (!onboardingDone) {
      finish(context);
      PSWelcomeScreen().launch(context);
      return;
    }

    await Future.delayed(Duration(seconds: 2));
    finish(context);
    PSDashboardScreen().launch(context);
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme)),
      child: Scaffold(
        backgroundColor: AppleColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              commonCacheImageWidget("images/playStore/app_ic_PlayStore.png", height: 90, width: 90),
              16.height,
              Text(
                'Zircon Labs',
                style: GoogleFonts.inter(color: AppleColors.textPrimary, fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: 0.2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
