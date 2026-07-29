import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:playstore_flutter/screens/PSSplashScreen.dart';
import 'package:playstore_flutter/store/AppStore.dart';
import 'package:playstore_flutter/utils/AppTheme.dart';
import 'package:playstore_flutter/utils/PSConstants.dart';

AppStore appStore = AppStore();
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initialize();
  appStore.toggleDarkMode(value: await _resolveIsDarkMode());
  runApp(MyApp());
}

/// Resolve o modo escuro a partir da preferência salva em Settings > Theme
/// ('system' | 'light' | 'dark', ver [PSSettingScreen]). Instalações que
/// nunca abriram essa tela ainda não têm [themeModePref] salvo - nesse
/// caso cai no comportamento antigo, lendo direto [isDarkModeOnPref].
Future<bool> _resolveIsDarkMode() async {
  final mode = await getStringAsync(themeModePref, defaultValue: '');
  switch (mode) {
    case 'dark':
      return true;
    case 'light':
      return false;
    case 'system':
      return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    default:
      return await getBool(isDarkModeOnPref, defaultValue: false);
  }
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        return MaterialApp(
          title: 'PlayStore flutter',
          theme: !appStore.isDarkModeOn ? AppThemeData.lightTheme : AppThemeData.darkTheme,
          builder: scrollBehaviour(),
          debugShowCheckedModeBanner: false,
          home: PSSplashScreen(),
        );
      },
    );
  }
}
