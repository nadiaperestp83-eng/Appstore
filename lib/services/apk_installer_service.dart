import 'dart:io';
import 'package:dio/dio.dart';
import 'package:device_apps/device_apps.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:playstore_flutter/models/store_app.dart';

class ApkInstallerException implements Exception {
  final String message;
  ApkInstallerException(this.message);

  @override
  String toString() => 'ApkInstallerException: $message';
}

class ApkInstallerService {
  static final ApkInstallerService _instance = ApkInstallerService._internal();
  factory ApkInstallerService() => _instance;
  ApkInstallerService._internal();

  final Dio _dio = Dio();

  Future<bool> isInstalled(String packageName) async {
    try {
      return await DeviceApps.isAppInstalled(packageName);
    } catch (e) {
      debugPrint('Erro ao verificar instalação: $e');
      return false;
    }
  }

  Future<void> installOrOpen(
    StoreApp app, {
    void Function(double progress)? onProgress,
  }) async {
    final knownPackageName = app.packageName;

    if (knownPackageName != null && knownPackageName.isNotEmpty) {
      final already = await isInstalled(knownPackageName);
      if (already) {
        final opened = await DeviceApps.openApp(knownPackageName);
        if (opened) return;
      }
    }

    final safeId = app.id.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final version = app.version.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final fileName = '${safeId}_$version.apk';

    await downloadAndInstall(
      app.downloadUrl,
      fileName: fileName,
      onProgress: onProgress,
    );
  }

  Future<void> downloadAndInstall(
    String downloadUrl, {
    required String fileName,
    void Function(double progress)? onProgress,
  }) async {
    final granted = await _ensureInstallPermission();
    if (!granted) {
      throw ApkInstallerException(
        'Permissão para instalar aplicativos desconhecidos foi negada.',
      );
    }

    final file = await _download(downloadUrl, fileName, onProgress);

    final result = await OpenFile.open(
      file.path,
      type: 'application/vnd.android.package-archive',
    );

    if (result.type != ResultType.done) {
      throw ApkInstallerException(
        'Não foi possível iniciar a instalação: ${result.message}',
      );
    }
  }

  Future<bool> _ensureInstallPermission() async {
    if (!Platform.isAndroid) return false;

    final status = await Permission.requestInstallPackages.status;
    if (status.isGranted) return true;

    final requested = await Permission.requestInstallPackages.request();
    return requested.isGranted;
  }

  Future<File> _download(
    String url,
    String fileName,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final savePath = '${tempDir.path}/$fileName';

      await _dio.download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total > 0 && onProgress != null) {
            onProgress(received / total);
          }
        },
        options: Options(
          followRedirects: true,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      return File(savePath);
    } on DioException catch (e) {
      throw ApkInstallerException('Falha no download: ${e.message}');
    } catch (e) {
      throw ApkInstallerException('Erro inesperado no download: $e');
    }
  }
}
