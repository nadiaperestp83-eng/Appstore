import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:playstore_flutter/model/PSModel.dart';
import 'package:playstore_flutter/models/store_app.dart';
import 'package:playstore_flutter/services/apk_installer_service.dart';
import 'package:playstore_flutter/utils/AppColors.dart';
import 'package:playstore_flutter/utils/AppWidget.dart';
import 'package:playstore_flutter/utils/PSColor.dart';

/// Instância única do serviço de instalação para o app inteiro. Todo botão
/// de instalar (listagens + tela de detalhes) passa por aqui - é o "Serviço
/// Central de instalação" pedido: um único lugar decide como baixar e
/// acionar o instalador nativo, nenhuma tela reimplementa essa lógica.
final ApkInstallerService _sharedInstaller = ApkInstallerService();

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

  StoreApp? get _storeApp {
    final data = widget.app;
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
      );
      if (!mounted) return;
      setState(() => _status = _InstallStatus.installed);
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
          color: psColorGreen,
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
          child: Text('Abrir', style: primaryTextStyle(color: psColorGreen)),
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
          color: psColorGreen,
          onTap: _handleTap,
          child: Text('Instalar', style: primaryTextStyle(color: Colors.white)),
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
          borderColor: psColorGreen,
          onTap: null,
          child: Text(
            _progress > 0 ? '${(_progress * 100).toStringAsFixed(0)}%' : '...',
            style: secondaryTextStyle(color: psColorGreen, size: 11),
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
          color: psColorGreen,
          borderColor: psColorGreen,
          onTap: _handleTap,
          child: Text('Instalar', style: secondaryTextStyle(color: Colors.white, size: 11)),
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
