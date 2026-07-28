import 'dart:io';
import 'dart:typed_data';
import 'package:device_apps/device_apps.dart';

/// Um app real instalado no aparelho (não confundir com [StoreApp], que é
/// um app disponível pra instalar vindo de uma loja/repositório).
class InstalledAppInfo {
  final String packageName;
  final String appName;
  final String versionName;
  final int versionCode;
  final Uint8List? iconBytes;
  final int sizeBytes;
  final DateTime installedAt;
  final DateTime updatedAt;
  final Application _raw;

  InstalledAppInfo._({
    required this.packageName,
    required this.appName,
    required this.versionName,
    required this.versionCode,
    required this.iconBytes,
    required this.sizeBytes,
    required this.installedAt,
    required this.updatedAt,
    required Application raw,
  }) : _raw = raw;

  /// Abre o app de verdade (usa o método da própria instância retornada
  /// pelo device_apps, sem precisar de outra chamada estática).
  Future<bool?> open() => _raw.openApp();
}

/// Lista os apps de verdade instalados no aparelho via `device_apps`.
class InstalledAppsService {
  /// Apenas apps com ícone no launcher (mesmo critério da Play Store),
  /// sem apps de sistema.
  Future<List<InstalledAppInfo>> listLauncherApps() async {
    if (!Platform.isAndroid) return [];

    List<Application> apps;
    try {
      apps = await DeviceApps.getInstalledApplications(
        onlyAppsWithLaunchIntent: true,
        includeSystemApps: false,
        includeAppIcons: true,
      ).timeout(const Duration(seconds: 25));
    } catch (e) {
      // ignore: avoid_print
      print('[InstalledAppsService] Falha ao listar apps instalados: $e');
      return [];
    }

    final result = <InstalledAppInfo>[];
    for (final app in apps) {
      try {
        int size = 0;
        try {
          if (app.apkFilePath.isNotEmpty) {
            size = await File(app.apkFilePath).length();
          }
        } catch (_) {
          // Sem permissão de leitura direta em alguns aparelhos - tudo bem,
          // só fica sem o tamanho real desse item específico.
        }

        result.add(InstalledAppInfo._(
          packageName: app.packageName,
          appName: app.appName,
          versionName: app.versionName ?? '',
          versionCode: app.versionCode,
          iconBytes: app is ApplicationWithIcon ? app.icon : null,
          sizeBytes: size,
          installedAt: DateTime.fromMillisecondsSinceEpoch(app.installTimeMillis),
          updatedAt: DateTime.fromMillisecondsSinceEpoch(app.updateTimeMillis),
          raw: app,
        ));
      } catch (e) {
        // ignore: avoid_print
        print('[InstalledAppsService] Item inválido ignorado: $e');
      }
    }

    result.sort((a, b) => a.appName.toLowerCase().compareTo(b.appName.toLowerCase()));
    return result;
  }
}
