import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:playstore_flutter/services/app_protect_service.dart';
import 'package:playstore_flutter/utils/AppleColors.dart';

/// Tela do "App Protect" - substitui de vez o antigo mock de "Play
/// Protect" (que tinha ícones aleatórios do picsum.photos e um histórico
/// de scan totalmente inventado). Tudo aqui é real:
/// - O interruptor Ativar/Desativar persiste de verdade (ver
///   AppProtectService.isEnabled/setEnabled), estilo iOS (CupertinoSwitch).
/// - O "verificado recentemente" vem do histórico real de inspeções que o
///   AppProtectService grava a cada instalação (ver
///   AppProtectService.getScanHistory) - nada de fotos/nomes inventados.
///
/// Nome da classe mantido como `PSPlayProtectScreen` só pelo nome do
/// arquivo/rota já existente (import único em AppleProfileMenuSheet.dart);
/// o conteúdo e a marca visível ao usuário são 100% "App Protect".
class PSPlayProtectScreen extends StatefulWidget {
  static String tag = '/PSPlayProtectScreen';

  @override
  PSPlayProtectScreenState createState() => PSPlayProtectScreenState();
}

class PSPlayProtectScreenState extends State<PSPlayProtectScreen> {
  bool _loading = true;
  bool _enabled = true;
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final enabled = await AppProtectService.instance.isEnabled();
    final history = await AppProtectService.instance.getScanHistory();
    if (!mounted) return;
    setState(() {
      _enabled = enabled;
      _history = history;
      _loading = false;
    });
  }

  Future<void> _toggle(bool value) async {
    setState(() => _enabled = value);
    await AppProtectService.instance.setEnabled(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppleColors.backgroundSecondary,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppleColors.background,
        iconTheme: IconThemeData(color: AppleColors.textPrimary),
        title: Text('App Protect', style: boldTextStyle(color: AppleColors.textPrimary)),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.all(16),
              children: [
                _buildStatusHeader(),
                20.height,
                _buildToggleCard(),
                20.height,
                _buildAboutCard(),
                20.height,
                _buildHistorySection(),
              ],
            ),
    );
  }

  Widget _buildStatusHeader() {
    final color = _enabled ? AppleColors.accentBlue : AppleColors.textSecondary;
    return Column(
      children: [
        Icon(_enabled ? Icons.shield_rounded : Icons.shield_outlined, color: color, size: 64),
        12.height,
        Text(
          _enabled ? 'App Protect está ativo' : 'App Protect está desativado',
          style: boldTextStyle(size: 17, color: AppleColors.textPrimary),
        ),
        6.height,
        Text(
          _enabled
              ? 'Verificação rápida e local antes de cada instalação.'
              : 'Nenhuma verificação é feita antes de instalar.',
          style: secondaryTextStyle(color: AppleColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildToggleCard() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: AppleColors.background, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Text('Ativar App Protect', style: primaryTextStyle(color: AppleColors.textPrimary, size: 15)).expand(),
          CupertinoSwitch(
            value: _enabled,
            activeTrackColor: AppleColors.accentBlue,
            onChanged: _toggle,
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppleColors.background, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Como funciona', style: boldTextStyle(size: 15, color: AppleColors.textPrimary)),
          10.height,
          _aboutLine(Icons.bolt_rounded, 'Rápido: roda em milissegundos, tudo local (sem enviar seu .apk pra nenhum servidor).'),
          _aboutLine(Icons.link_rounded, 'Confere se o link de download veio de uma origem conhecida (GitHub, F-Droid, Codeberg, etc).'),
          _aboutLine(Icons.fingerprint_rounded, 'Compara o arquivo com uma lista de ameaças confirmadas (hash SHA-256).'),
          _aboutLine(Icons.visibility_outlined, 'Avisa (sem bloquear) quando o app pede permissões sensíveis, como SMS ou chamadas.'),
          14.height,
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppleColors.backgroundSecondary, borderRadius: BorderRadius.circular(10)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.verified_user_outlined, color: AppleColors.accentBlue, size: 18),
                10.width,
                Text(
                  'Nunca verifica ou exige assinatura/keystore. APKs de debug, forks e builds locais (inclusive compilados no próprio celular) são sempre aceitos sem alerta.',
                  style: secondaryTextStyle(color: AppleColors.textSecondary, size: 12.5),
                ).expand(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _aboutLine(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppleColors.textSecondary),
          10.width,
          Text(text, style: secondaryTextStyle(color: AppleColors.textSecondary, size: 13)).expand(),
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Verificações recentes', style: boldTextStyle(size: 15, color: AppleColors.textPrimary)),
        10.height,
        if (_history.isEmpty)
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppleColors.background, borderRadius: BorderRadius.circular(14)),
            child: Text(
              'Nenhuma instalação verificada ainda nesta sessão. Assim que você instalar um app, o resultado real aparece aqui.',
              style: secondaryTextStyle(color: AppleColors.textSecondary),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(color: AppleColors.background, borderRadius: BorderRadius.circular(14)),
            child: Column(
              children: _history.asMap().entries.map((entry) {
                final isLast = entry.key == _history.length - 1;
                return _buildHistoryTile(entry.value, showDivider: !isLast);
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildHistoryTile(Map<String, dynamic> item, {required bool showDivider}) {
    final isKnownMalware = item['isKnownMalware'] == true;
    final sensitiveCount = (item['sensitivePermissionsCount'] as num?)?.toInt() ?? 0;
    final elapsedMs = (item['elapsedMs'] as num?)?.toInt() ?? 0;
    final label = (item['label'] as String?) ?? 'App';
    final timestamp = DateTime.tryParse((item['timestamp'] as String?) ?? '');

    final IconData icon;
    final Color color;
    final String statusText;
    if (isKnownMalware) {
      icon = Icons.gpp_bad_rounded;
      color = Colors.red;
      statusText = 'Bloqueado (ameaça confirmada)';
    } else if (sensitiveCount > 0) {
      icon = Icons.gpp_maybe_rounded;
      color = Colors.orange[700]!;
      statusText = '$sensitiveCount permissão(ões) sensível(is) - só aviso';
    } else {
      icon = Icons.verified_user_rounded;
      color = AppleColors.accentBlue;
      statusText = 'Sem alertas';
    }

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              12.width,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: primaryTextStyle(color: AppleColors.textPrimary, size: 14)),
                  2.height,
                  Text(statusText, style: secondaryTextStyle(color: AppleColors.textSecondary, size: 12)),
                ],
              ).expand(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${elapsedMs}ms', style: secondaryTextStyle(color: AppleColors.textSecondary, size: 11)),
                  if (timestamp != null) Text(_formatTime(timestamp), style: secondaryTextStyle(color: AppleColors.textSecondary, size: 11)),
                ],
              ),
            ],
          ),
        ),
        if (showDivider) Divider(height: 1, thickness: 1, indent: 16, endIndent: 16, color: AppleColors.divider),
      ],
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inMinutes < 1) return 'agora';
    if (diff.inHours < 1) return '${diff.inMinutes}min';
    if (diff.inDays < 1) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}
