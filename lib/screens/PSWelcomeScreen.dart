import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:playstore_flutter/screens/PSPermissionsScreen.dart';
import 'package:playstore_flutter/utils/AppleColors.dart';

/// Passo 1/2 do onboarding de primeira abertura: tela de boas-vindas.
/// Mesma estrutura da tela "Boas-vindas" da Aurora Store (título grande,
/// lista de itens com ícone, indicador de página, "Pular"/"Avançar" no
/// rodapé), mas com as cores, tipografia e componentes do resto do nosso
/// app (ver [AppleColors] e a fonte Inter usada em Settings).
///
/// Só aparece uma vez: [PSSplashScreen] só manda pra cá enquanto
/// [hasCompletedOnboardingPref] ainda não foi marcado como concluído (isso
/// acontece no fim de [PSPermissionsScreen]).
class PSWelcomeScreen extends StatelessWidget {
  static String tag = '/PSWelcomeScreen';

  const PSWelcomeScreen({super.key});

  static const _items = [
    (
      icon: Icons.explore_outlined,
      title: 'Explore',
      subtitle: 'Milhares de apps e jogos para descobrir, organizados por categoria.',
    ),
    (
      icon: Icons.travel_explore_outlined,
      title: 'Apps livres',
      subtitle: 'Catálogo de código aberto, direto do F-Droid e do GitHub.',
    ),
    (
      icon: Icons.install_mobile_outlined,
      title: 'Instalação rápida',
      subtitle: 'Baixe e instale com um toque, sem passos extras.',
    ),
  ];

  void _next(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => PSPermissionsScreen()));
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
                // Indicador de página: 2 passos, primeiro ativo.
                Row(
                  children: [
                    _dot(active: true),
                    6.width,
                    _dot(active: false),
                  ],
                ),
                32.height,
                Text('Welcome', style: GoogleFonts.inter(color: AppleColors.textPrimary, fontSize: 34, fontWeight: FontWeight.w700)),
                8.height,
                Text(
                  'Tudo que você precisa pra descobrir e instalar apps.',
                  style: GoogleFonts.inter(color: AppleColors.textSecondary, fontSize: 16),
                ),
                40.height,
                for (final item in _items) ...[
                  _WelcomeRow(icon: item.icon, title: item.title, subtitle: item.subtitle),
                  28.height,
                ],
                Spacer(),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => _next(context),
                      child: Text('Pular', style: GoogleFonts.inter(color: AppleColors.textSecondary, fontSize: 16)),
                    ),
                    Spacer(),
                    ElevatedButton(
                      onPressed: () => _next(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppleColors.accentBlue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                        elevation: 0,
                      ),
                      child: Text('Avançar', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
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
}

class _WelcomeRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _WelcomeRow({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 44,
          width: 44,
          decoration: BoxDecoration(color: AppleColors.backgroundSecondary, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: AppleColors.accentBlue, size: 24),
        ),
        14.width,
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
      ],
    );
  }
}
