import 'dart:async';
import 'package:flutter/services.dart';

/// Metadados de um .apk lidos direto do Android Package Manager (sem
/// instalar): nome do pacote, versão e as permissões declaradas no
/// manifesto (`android:uses-permission`).
class ApkManifestInfo {
  final String? packageName;
  final String? versionName;
  final List<String> permissions;

  ApkManifestInfo({this.packageName, this.versionName, required this.permissions});
}

/// Ponte para a Camada Nativa do App Protect (ver MainActivity.kt) - aciona
/// o `PackageManager.getPackageArchiveInfo()` do próprio Android pra ler o
/// manifesto de um .apk já baixado, sem instalar nada e sem depender de
/// nenhum pacote pub novo (é 100% MethodChannel + API nativa do Android).
class NativeApkInspector {
  static const MethodChannel _channel = MethodChannel('com.example.playstore_flutter/app_protect');

  /// Retorna null se não der pra inspecionar (arquivo corrompido, não é um
  /// .apk válido, plataforma não é Android, canal nativo indisponível,
  /// timeout etc.) - nunca lança pra cima: o App Protect trata "não deu
  /// pra inspecionar" exatamente como "sem sinal de alerta", nunca como
  /// bloqueio.
  Future<ApkManifestInfo?> inspect(String apkFilePath) async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'inspectApk',
        {'path': apkFilePath},
      ).timeout(const Duration(seconds: 5));

      if (result == null) return null;

      final permissions = (result['permissions'] as List?)?.map((p) => p.toString()).toList() ?? const <String>[];

      return ApkManifestInfo(
        packageName: result['packageName'] as String?,
        versionName: result['versionName'] as String?,
        permissions: permissions,
      );
    } catch (e) {
      // ignore: avoid_print
      print('[NativeApkInspector] Falha ao inspecionar "$apkFilePath": $e');
      return null;
    }
  }
}
