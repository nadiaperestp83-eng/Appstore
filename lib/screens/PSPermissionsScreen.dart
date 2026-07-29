import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:playstore_flutter/screens/PSSplashScreen.dart';
import 'package:playstore_flutter/utils/AppleColors.dart';
import 'package:playstore_flutter/utils/PSConstants.dart';

/// Passo 2/2 do onboarding: pede as permissões reais que o app usa.
///
/// Só existem 2 linhas, porque só existem 2 permissões que o app realmente
/// consome hoje:
/// - "Permissão de instalação" (NECESSÁRIO): `REQUEST_INSTALL_PACKAGES`,
///   sem ela o botão "Instalar" não consegue abrir o instalador do APK
///   baixado.
/// - "Notificações" (OPCIONAL): `POST_NOTIFICATIONS` (Android 13+).
///
/// Os outros itens do print de referência da Aurora Store (armazenamento,
/// downloads em segundo plano, links do app) não têm nenhuma permissão de
/// verdade por trás deles neste projeto ainda - não incluí pra não deixar
/// um botão "Permitir" que não faz nada.
class PSPermissionsScreen extends StatefulWidget {
  static String tag = '/PSPermissionsScreen';

  @override
  State<PSPermissionsScreen> createState() => _PSPermissionsScreenState();
}

class _PSPermissionsScreenState extends State<PSPermissionsScreen> with WidgetsBindingObserver {
  bool _installGranted = false;
  bool _notificationsGranted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshStatuses();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // A permissão de instalação é concedida numa tela do Android fora do
    // app (Configurações); precisamos reconferir quando o usuário volta.
    if (state == AppLifecycleState.resumed) _refreshStatuses();
  }

  Future<void> _refreshStatuses() async {
    final install = await Permission.requestInstallPackages.status;
    final notif = await Permission.notification.status;
    if (!mounted) return;
    setState(() {
      _installGranted = install.isGranted;
      _notificationsGranted = notif.isGranted;
    });
  }

  Future<void> _requestInstall() async {
    await Permission.requestInstallPackages.request();
    _refreshStatuses();
  }

  Future<void> _requestNotifications() async {
    await Permission.notification.request();
    _refreshStatuses();
  }

  Future<void> _finish() async {
    await setValue(hasCompletedOnboardingPref, true);
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => PSSplashScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme)),
      child: Scaffold(
        backgroundColor: AppleColors.background,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                24.height,
                Row(
                  children: [
                    _dot(active: false),
                    6.width,
                    _dot(active: true),
                  ],
                ),
                32.height,
                Text('Permissões', style: GoogleFonts.inter(color: AppleColors.textPrimary, fontSize: 34, fontWeight: FontWeight.w700)),
                8.height,
                Text(
                  'O app precisa das permissões abaixo para funcionar direito.',
                  style: GoogleFonts.inter(color: AppleColors.textSecondary, fontSize: 16),
                ),
                32.height,
                _sectionLabel('NECESSÁRIO'),
                12.height,
                _permissionRow(
                  title: 'Permissão de instalação',
                  subtitle: 'Permite instalar os apps baixados por este app.',
                  granted: _installGranted,
                  onTap: _requestInstall,
                ),
                28.height,
                _sectionLabel('OPCIONAL'),
                12.height,
                _permissionRow(
                  title: 'Notificações',
                  subtitle: 'Avisa sobre o andamento de downloads e instalações.',
                  granted: _notificationsGranted,
                  onTap: _requestNotifications,
                ),
                Spacer(),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Voltar', style: GoogleFonts.inter(color: AppleColors.textSecondary, fontSize: 16)),
                    ),
                    Spacer(),
                    ElevatedButton(
                      onPressed: _finish,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppleColors.accentBlue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                        elevation: 0,
                      ),
                      child: Text('Concluir', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                24.height,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dot({required bool active}) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      height: 8,
      width: active ? 20 : 8,
      decoration: BoxDecoration(
        color: active ? AppleColors.accentBlue : AppleColors.divider,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(text, style: GoogleFonts.inter(color: AppleColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.4));
  }

  Widget _permissionRow({
    required String title,
    required String subtitle,
    required bool granted,
    required VoidCallback onTap,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.inter(color: AppleColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
              4.height,
              Text(subtitle, style: GoogleFonts.inter(color: AppleColors.textSecondary, fontSize: 13.5, height: 1.3)),
            ],
          ),
        ),
        12.width,
        if (granted)
          Row(
            children: [
              Icon(Icons.check_circle_rounded, color: AppleColors.accentBlue, size: 18),
              4.width,
              Text('Permitido', style: GoogleFonts.inter(color: AppleColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          )
        else
          TextButton(
            onPressed: onTap,
            child: Text('Permitir', style: GoogleFonts.inter(color: AppleColors.accentBlue, fontSize: 14, fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }
}
