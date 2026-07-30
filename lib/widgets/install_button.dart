import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:playstore_flutter/model/PSModel.dart';
import 'package:playstore_flutter/models/store_app.dart';
import 'package:playstore_flutter/services/apk_installer_service.dart';
import 'package:playstore_flutter/services/app_protect_service.dart';
import 'package:playstore_flutter/utils/AppColors.dart';
import 'package:playstore_flutter/utils/AppWidget.dart';
import 'package:playstore_flutter/utils/AppleColors.dart';

/// Instância única do serviço de instalação para o app inteiro. Todo botão
/// de instalar (listagens + tela de detalhes) passa por aqui - é o "Serviço
/// Central de instalação" pedido: um único lugar decide como baixar e
/// acionar o instalador nativo, nenhuma tela reimplementa essa lógica.
final ApkInstallerService _sharedInstaller = ApkInstallerService();

/// Converte um [PSGameModel] real (com packageName/downloadUrl) pro
/// [StoreApp] que o [ApkInstallerService] espera. Retorna null se o item
/// não tiver dado real o bastante pra instalar (ex: mock de Movies/Books
/// ainda não migrado).
StoreApp? storeAppFromGameModel(PSGameModel data) {
  final packageName = data.packageName;
  final downloadUrl = data.downloadUrl;
  if (packageName == null || packageName.isEmpty || downloadUrl == null || downloadUrl.isEmpty) {
    return null;
  }
  return StoreApp(
    id: packageName,
    title: data.title ?? '',
    version: data.version ?? '',
    iconUrl: data.imgLogo ?? data.imgMain ?? '',
    downloadUrl: downloadUrl,
    description: data.subTitle ?? '',
    source: (data.preferredRepoLabel ?? '').toLowerCase(),
    packageName: packageName,
    repoLabel: data.preferredRepoLabel ?? '',
  );
}

/// Dispara a instalação de um [PSGameModel] fora de um [InstallButton] (ex:
/// "Update all" na aba Updates, que precisa iniciar a primeira atualização
/// programaticamente). Passa pelo mesmo Serviço Central de instalação.
Future<void> triggerInstall(PSGameModel app, {void Function(double progress)? onProgress}) async {
  final storeApp = storeAppFromGameModel(app);
  if (storeApp == null) return;
  await _sharedInstaller.installOrOpen(storeApp, onProgress: onProgress);
}

enum InstallButtonSize { small, large }

enum _InstallStatus { checking, notInstalled, installing, installed, error, permissionRequired, unavailable }

/// Botão de instalar/abrir reutilizável. Use [InstallButtonSize.large] na
/// tela de detalhes e [InstallButtonSize.small] nas listagens/cards.
///
/// Recebe um [PSGameModel] porque é o tipo que todas as telas já usam pra
/// exibir apps; internamente ele é convertido pro [StoreApp] real que o
/// [ApkInstallerService] espera. Se o item não tiver dado real (packageName
/// / downloadUrl), o botão fica desabilitado em vez de quebrar - acontece
/// hoje com Movies/Books, que ainda não foram migrados pra uma fonte real.
class InstallButton extends StatefulWidget {
  final PSGameModel app;
  final InstallButtonSize size;

  const InstallButton({
    super.key,
    required this.app,
    this.size = InstallButtonSize.large,
  });

  @override
  State<InstallButton> createState() => _InstallButtonState();
}

class _InstallButtonState extends State<InstallButton> with WidgetsBindingObserver {
  _InstallStatus _status = _InstallStatus.checking;
  double _progress = 0;
  String? _errorMessage;

  StoreApp? get _storeApp => storeAppFromGameModel(widget.app);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshInstalledState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // O usuário só sai do app pra ir na tela "Instalar apps desconhecidos"
    // das Configurações. Quando ele volta (app resumido) enquanto o botão
    // está nesse estado, tenta instalar de novo automaticamente - assim
    // ninguém precisa entender que precisa tocar de novo manualmente.
    if (state == AppLifecycleState.resumed && _status == _InstallStatus.permissionRequired) {
      _handleTap();
    }
  }

  Future<void> _refreshInstalledState() async {
    final app = _storeApp;
    if (app == null) {
      if (mounted) setState(() => _status = _InstallStatus.unavailable);
      return;
    }
    final installed = await _sharedInstaller.isInstalled(app.packageName!);
    if (!mounted) return;
    setState(() => _status = installed ? _InstallStatus.installed : _InstallStatus.notInstalled);
  }

  Future<void> _handleTap() async {
    final app = _storeApp;
    if (app == null) return;

    if (_status == _InstallStatus.installed) {
      await _refreshInstalledState(); // reabre via installOrOpen abaixo se ainda instalado
    }

    setState(() {
      _status = _InstallStatus.installing;
      _progress = 0;
      _errorMessage = null;
    });

    try {
      await _sharedInstaller.installOrOpen(
        app,
        onProgress: (p) {
          if (!mounted) return;
          setState(() => _progress = p);
        },
        onSecurityWarning: (verdict) => _showAppProtectWarning(context, verdict),
      );
      if (!mounted) return;
      setState(() => _status = _InstallStatus.installed);
    } on ApkInstallerSecurityException catch (e) {
      if (!mounted) return;
      setState(() {
        _status = _InstallStatus.error;
        _errorMessage = e.message;
      });
      toast(e.message);
    } on ApkInstallerPermissionRequiredException catch (e) {
      if (!mounted) return;
      setState(() {
        _status = _InstallStatus.permissionRequired;
        _errorMessage = e.message;
      });
      toast(e.message);
    } on ApkInstallerException catch (e) {
      if (!mounted) return;
      setState(() {
        _status = _InstallStatus.error;
        _errorMessage = e.message;
      });
      toast(e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = _InstallStatus.error;
        _errorMessage = 'Erro inesperado ao instalar: $e';
      });
      toast(_errorMessage!);
    }
  }

  /// Aviso NEUTRO de transparência do App Protect: mostra as permissões
  /// sensíveis que o manifesto do .apk declara e deixa a decisão 100% com
  /// o usuário - "Continuar mesmo assim" e "Cancelar" são igualmente
  /// acessíveis, nenhuma delas é forçada. Nunca aparece por causa de
  /// assinatura/keystore/fork - só por permissões (ver AppProtectService).
  Future<bool> _showAppProtectWarning(BuildContext context, AppProtectVerdict verdict) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(color: AppleColors.background, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          padding: EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(color: AppleColors.divider, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              20.height,
              Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: Colors.orange[700], size: 24),
                  10.width,
                  Text('App Protect', style: boldTextStyle(size: 17, color: AppleColors.textPrimary)).expand(),
                ],
              ),
              12.height,
              Text(
                'Este app pede permissões que vale a pena conhecer antes de instalar. Isto é só um aviso - você decide.',
                style: secondaryTextStyle(color: AppleColors.textSecondary),
              ),
              16.height,
              ...verdict.sensitivePermissions.map(
                (p) => Padding(
                  padding: EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(Icons.circle, size: 5, color: AppleColors.textSecondary),
                      8.width,
                      Text(_humanReadablePermission(p), style: primaryTextStyle(color: AppleColors.textPrimary, size: 13)),
                    ],
                  ),
                ),
              ),
              20.height,
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 12)),
                      child: Text('Cancelar'),
                    ),
                  ),
                  12.width,
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(backgroundColor: AppleColors.accentBlue, padding: EdgeInsets.symmetric(vertical: 12)),
                      child: Text('Continuar mesmo assim', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
    // Fechar o sheet sem escolher (ex: tocar fora) equivale a "continuar" -
    // é só um aviso, nunca um bloqueio silencioso.
    return result ?? true;
  }

  String _humanReadablePermission(String androidPermission) {
    const labels = {
      'android.permission.SEND_SMS': 'Enviar SMS',
      'android.permission.RECEIVE_SMS': 'Receber SMS',
      'android.permission.READ_SMS': 'Ler SMS',
      'android.permission.CALL_PHONE': 'Fazer ligações',
      'android.permission.READ_CALL_LOG': 'Ler histórico de chamadas',
      'android.permission.WRITE_CALL_LOG': 'Modificar histórico de chamadas',
      'android.permission.PROCESS_OUTGOING_CALLS': 'Monitorar chamadas realizadas',
      'android.permission.BIND_DEVICE_ADMIN': 'Administrador do dispositivo',
      'android.permission.BIND_ACCESSIBILITY_SERVICE': 'Serviço de acessibilidade',
      'android.permission.SYSTEM_ALERT_WINDOW': 'Exibir sobre outros apps',
      'android.permission.REQUEST_INSTALL_PACKAGES': 'Instalar outros apps',
    };
    return labels[androidPermission] ?? androidPermission.replaceFirst('android.permission.', '');
  }

  @override
  Widget build(BuildContext context) {
    return widget.size == InstallButtonSize.large ? _buildLarge(context) : _buildSmall(context);
  }

  // ===== Tamanho grande (PSDetailScreen) =====
  Widget _buildLarge(BuildContext context) {
    switch (_status) {
      case _InstallStatus.checking:
        return _largeShell(
          color: appDividerColor,
          child: SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)),
        );
      case _InstallStatus.unavailable:
        return _largeShell(
          color: appDividerColor,
          child: Text('Indisponível', style: primaryTextStyle(color: Colors.black38)),
        );
      case _InstallStatus.installing:
        return _largeShell(
          color: AppleColors.accentBlue,
          onTap: null,
          child: Text(
            _progress > 0 ? 'Instalando ${(_progress * 100).toStringAsFixed(0)}%' : 'Instalando...',
            style: primaryTextStyle(color: Colors.white),
          ),
        );
      case _InstallStatus.installed:
        return _largeShell(
          color: appDividerColor,
          onTap: _handleTap,
          child: Text('Abrir', style: primaryTextStyle(color: AppleColors.accentBlue)),
        );
      case _InstallStatus.permissionRequired:
        return _largeShell(
          color: Colors.orange[50],
          onTap: _handleTap,
          child: Text('Autorizar nas Configurações e tentar de novo', style: primaryTextStyle(color: Colors.orange[800]), textAlign: TextAlign.center),
        );
      case _InstallStatus.error:
        return _largeShell(
          color: Colors.red[50],
          onTap: _handleTap,
          child: Text('Tentar novamente', style: primaryTextStyle(color: Colors.red[700])),
        );
      case _InstallStatus.notInstalled:
        return _largeShell(
          color: AppleColors.accentBlue,
          onTap: _handleTap,
          child: Text('Install', style: primaryTextStyle(color: Colors.white)),
        );
    }
  }

  Widget _largeShell({required Color? color, required Widget child, VoidCallback? onTap}) {
    return Container(
      decoration: boxDecoration(bgColor: color, radius: 8),
      width: double.infinity,
      height: 35,
      child: Center(child: child),
    ).onTap(onTap);
  }

  // ===== Tamanho pequeno (cards de listagem) =====
  Widget _buildSmall(BuildContext context) {
    switch (_status) {
      case _InstallStatus.checking:
        return SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2));
      case _InstallStatus.unavailable:
        return SizedBox.shrink();
      case _InstallStatus.installing:
        return _smallShell(
          color: Colors.transparent,
          borderColor: AppleColors.accentBlue,
          onTap: null,
          child: Text(
            _progress > 0 ? '${(_progress * 100).toStringAsFixed(0)}%' : '...',
            style: secondaryTextStyle(color: AppleColors.accentBlue, size: 11),
          ),
        );
      case _InstallStatus.installed:
        return _smallShell(
          color: Colors.transparent,
          borderColor: Colors.grey[400],
          onTap: _handleTap,
          child: Text('Abrir', style: secondaryTextStyle(size: 11)),
        );
      case _InstallStatus.permissionRequired:
        return _smallShell(
          color: Colors.transparent,
          borderColor: Colors.orange[300],
          onTap: _handleTap,
          child: Text('Autorizar', style: secondaryTextStyle(color: Colors.orange[800], size: 11)),
        );
      case _InstallStatus.error:
        return _smallShell(
          color: Colors.transparent,
          borderColor: Colors.red[300],
          onTap: _handleTap,
          child: Icon(Icons.refresh, size: 14, color: Colors.red[700]),
        );
      case _InstallStatus.notInstalled:
        return _smallShell(
          color: AppleColors.accentBlue,
          borderColor: AppleColors.accentBlue,
          onTap: _handleTap,
          child: Text('Install', style: secondaryTextStyle(color: Colors.white, size: 11)),
        );
    }
  }

  Widget _smallShell({required Color? color, required Color? borderColor, required Widget child, VoidCallback? onTap}) {
    return Container(
      height: 26,
      padding: EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor ?? Colors.grey),
      ),
      child: Center(child: child),
    ).onTap(onTap);
  }
}
