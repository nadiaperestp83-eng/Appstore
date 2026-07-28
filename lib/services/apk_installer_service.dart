import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_device_apps/flutter_device_apps.dart';
import '../models/store_app.dart';

class ApkInstallerException implements Exception {
  final String message;
  ApkInstallerException(this.message);
  @override
  String toString() => 'ApkInstallerException: $message';
}

/// Lançada quando a permissão "Instalar apps desconhecidos" ainda não foi
/// concedida. Diferente das outras falhas: aqui a tela de Configurações do
/// Android já foi aberta para o usuário autorizar - a UI deve avisar isso
/// claramente (não é um erro definitivo, é "volte e tente de novo").
class ApkInstallerPermissionRequiredException implements Exception {
  final String message;
  ApkInstallerPermissionRequiredException(this.message);
  @override
  String toString() => 'ApkInstallerPermissionRequiredException: $message';
}

/// Baixa um .apk e aciona o instalador nativo do Android.
/// Se o app já foi instalado/aberto nesta sessão (ver [isInstalled]), abre
/// o app em vez de reinstalar.
class ApkInstallerService {
  final http.Client _client;
  ApkInstallerService({http.Client? client}) : _client = client ?? http.Client();

  // `FlutterDeviceApps.isAppInstalled` não compila neste
  // projeto - a versão resolvida do pacote não expõe esse método do jeito
  // documentado (erro: "Member not found: 'FlutterDeviceApps.isAppInstalled'").
  // Em vez de depender dele, controlamos localmente quais pacotes foram
  // instalados/abertos nesta sessão do app. `FlutterDeviceApps.openApp` continua
  // em uso normalmente (não é o método que está quebrado).
  static final Set<String> _installedThisSession = {};

  /// Verifica se o pacote já foi instalado durante esta sessão do app.
  /// Não é uma checagem real do sistema operacional (isso exigiria
  /// `FlutterDeviceApps.isAppInstalled`, que está quebrado nesta versão do
  /// pacote) - então, ao reabrir o app do zero, tudo volta a aparecer como
  /// "não instalado" mesmo que já esteja no aparelho. É um trade-off
  /// deliberado para não travar o build por causa de uma API instável.
  Future<bool> isInstalled(String packageName) async {
    return _installedThisSession.contains(packageName);
  }

  /// Fluxo principal: se o app já foi instalado/aberto nesta sessão, abre-o.
  /// Caso contrário, baixa o .apk e aciona o instalador do sistema.
  Future<void> installOrOpen(
    StoreApp app, {
    void Function(double progress)? onProgress,
  }) async {
    final knownPackageName = app.packageName;
    if (knownPackageName != null && knownPackageName.isNotEmpty) {
      final already = await isInstalled(knownPackageName);
      if (already) {
        final opened = await FlutterDeviceApps.openApp(knownPackageName);
        if (opened != true) {
          throw ApkInstallerException('Não foi possível abrir "${app.title}" ($knownPackageName).');
        }
        return;
      }
    }

    final fileName = '${app.id.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_')}_${app.version}.apk';
    // Timeout duro no fluxo inteiro: nada aqui (download, gravação em disco,
    // permissão, abertura do instalador) pode deixar o botão preso na barra
    // de progresso pra sempre, mesmo se algum plugin nativo travar.
    await downloadAndInstall(app.downloadUrl, fileName: fileName, onProgress: onProgress).timeout(
      const Duration(minutes: 3),
      onTimeout: () => throw ApkInstallerException(
        'A instalação demorou demais e foi cancelada. Verifique sua conexão e tente de novo.',
      ),
    );

    // A partir daqui o instalador nativo do Android abriu com sucesso; a
    // confirmação final é do usuário na tela do sistema. Marcamos como
    // "instalado" nesta sessão pra próxima vez oferecer "Abrir" em vez de
    // "Instalar" de novo.
    if (knownPackageName != null && knownPackageName.isNotEmpty) {
      _installedThisSession.add(knownPackageName);
    }
  }

  /// Baixa o .apk de [downloadUrl] e abre o instalador nativo do Android.
  Future<void> downloadAndInstall(
    String downloadUrl, {
    required String fileName,
    void Function(double progress)? onProgress,
  }) async {
    if (!downloadUrl.toLowerCase().endsWith('.apk')) {
      throw ApkInstallerException('URL não aponta para um .apk direto: $downloadUrl');
    }

    final permissionResult = await _ensureInstallPermission();
    if (permissionResult == _PermissionOutcome.openedSettingsForUser) {
      throw ApkInstallerPermissionRequiredException(
        'Autorize "Instalar apps desconhecidos" para este app na tela que abriu e toque em Instalar de novo.',
      );
    }

    final file = await _download(downloadUrl, fileName, onProgress);
    final result = await OpenFile.open(file.path);

    if (result.type != ResultType.done) {
      throw ApkInstallerException(
        'Falha ao abrir o instalador: ${result.message} (${result.type})',
      );
    }
  }

  /// A permissão "Instalar apps desconhecidos" (REQUEST_INSTALL_PACKAGES) não
  /// é uma permissão comum: `.request()` abre a tela de Configurações do
  /// Android para o usuário autorizar manualmente e o Future retorna quase
  /// na hora, SEM esperar o usuário voltar. Por isso nunca tratamos o
  /// resultado de `.request()` como resposta definitiva de "negado" - só
  /// como "as Configurações foram abertas, avise o usuário pra tentar de
  /// novo depois". Também colocamos timeout: em alguns aparelhos/versões do
  /// plugin esse `await` pode nunca resolver, e isso é exatamente o que
  /// fazia o botão ficar preso na barra de progresso pra sempre.
  Future<_PermissionOutcome> _ensureInstallPermission() async {
    if (!Platform.isAndroid) return _PermissionOutcome.granted;

    PermissionStatus status;
    try {
      status = await Permission.requestInstallPackages.status.timeout(const Duration(seconds: 10));
    } catch (_) {
      status = PermissionStatus.denied;
    }
    if (status.isGranted) return _PermissionOutcome.granted;

    try {
      await Permission.requestInstallPackages.request().timeout(const Duration(seconds: 10));
    } catch (_) {
      // Se travar/der erro, cai no mesmo tratamento de "abriu configurações,
      // usuário precisa voltar e tentar de novo" abaixo.
    }

    // Reconsulta o status: em alguns devices o request() já reflete a
    // resposta (ex.: usuário já tinha autorizado antes); na maioria dos
    // casos ainda estará "denied" porque a troca só acontece depois que o
    // usuário mexe nas Configurações e volta pro app.
    PermissionStatus recheck;
    try {
      recheck = await Permission.requestInstallPackages.status.timeout(const Duration(seconds: 10));
    } catch (_) {
      recheck = status;
    }
    if (recheck.isGranted) return _PermissionOutcome.granted;

    return _PermissionOutcome.openedSettingsForUser;
  }

  Future<File> _download(
    String url,
    String fileName,
    void Function(double progress)? onProgress,
  ) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');

    http.StreamedResponse response;
    try {
      final request = http.Request('GET', Uri.parse(url));
      response = await _client.send(request).timeout(const Duration(seconds: 30));
    } catch (e) {
      throw ApkInstallerException('Erro de rede ao baixar APK: $e');
    }

    if (response.statusCode != 200) {
      throw ApkInstallerException('Falha no download (HTTP ${response.statusCode})');
    }

    final total = response.contentLength ?? 0;
    var received = 0;
    final sink = file.openWrite();

    try {
      await response.stream.map((chunk) {
        received += chunk.length;
        if (total > 0) onProgress?.call(received / total);
        return chunk;
      }).pipe(sink);
    } catch (e) {
      await sink.close();
      throw ApkInstallerException('Erro ao gravar arquivo APK: $e');
    }
    await sink.close();

    if (!await file.exists() || await file.length() == 0) {
      throw ApkInstallerException('Arquivo APK baixado está vazio ou corrompido.');
    }

    return file;
  }

  void dispose() => _client.close();
}

enum _PermissionOutcome { granted, openedSettingsForUser }
