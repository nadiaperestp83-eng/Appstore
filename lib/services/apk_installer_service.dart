import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_apps/device_apps.dart';
import '../models/store_app.dart';

class ApkInstallerException implements Exception {
  final String message;
  ApkInstallerException(this.message);
  @override
  String toString() => 'ApkInstallerException: $message';
}

/// Baixa um .apk e aciona o instalador nativo do Android.
/// Se o app já estiver instalado (checagem por package name, disponível
/// para apps de origem 'fdroid'), abre o app em vez de reinstalar.
class ApkInstallerService {
  final http.Client _client;
  ApkInstallerService({http.Client? client}) : _client = client ?? http.Client();

  /// Verifica se o pacote já está instalado no dispositivo.
  /// Só funciona de forma confiável para apps 'fdroid', cujo StoreApp.id
  /// é o package name real. Para 'github', o package name não é conhecido
  /// antecipadamente (só existe dentro do .apk).
  Future<bool> isInstalled(String packageName) async {
    if (!Platform.isAndroid) return false;
    try {
      return await DeviceApps.isAppInstalled(packageName);
    } catch (_) {
      return false;
    }
  }

  /// Fluxo principal: se o app já está instalado, abre-o.
  /// Caso contrário, baixa o .apk e aciona o instalador do sistema.
  Future<void> installOrOpen(
    StoreApp app, {
    void Function(double progress)? onProgress,
  }) async {
    if (app.source == 'fdroid') {
      final already = await isInstalled(app.id);
      if (already) {
        final opened = await DeviceApps.openApp(app.id);
        if (opened != true) {
          throw ApkInstallerException('Não foi possível abrir "${app.title}" (${app.id}).');
        }
        return;
      }
    }

    final fileName = '${app.id.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_')}_${app.version}.apk';
    await downloadAndInstall(app.downloadUrl, fileName: fileName, onProgress: onProgress);
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

    final granted = await _ensureInstallPermission();
    if (!granted) {
      throw ApkInstallerException(
        'Permissão "Instalar apps desconhecidos" não concedida pelo usuário.',
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

  Future<bool> _ensureInstallPermission() async {
    if (!Platform.isAndroid) return true;
    final status = await Permission.requestInstallPackages.status;
    if (status.isGranted) return true;
    final result = await Permission.requestInstallPackages.request();
    return result.isGranted;
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
