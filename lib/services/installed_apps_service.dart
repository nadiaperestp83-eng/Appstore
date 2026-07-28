import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_device_apps/flutter_device_apps.dart';

class InstalledAppInfo {
  final String packageName;
  final String appName;
  final String versionName;
  final int versionCode;
  final Uint8List? iconBytes;
  final int sizeBytes;
  final DateTime installedAt;
  final DateTime updatedAt;
  final dynamic _raw;

  InstalledAppInfo._({
    required this.packageName,
    required this.appName,
    required this.versionName,
    required this.versionCode,
    required this.iconBytes,
    required this.sizeBytes,
    required this.installedAt,
    required this.updatedAt,
    required dynamic raw,
  }) : _raw = raw;

  Future<bool?> open() => FlutterDeviceApps.openApp(packageName);
}

class InstalledAppsService {
  Future<List<InstalledAppInfo>> listLauncherApps() async {
    if (!Platform.isAndroid) return [];

    List<dynamic> apps = [];
    try {
      final result = await FlutterDeviceApps.getInstalledApps(
        includeAppIcons: true,
        includeSystemApps: false,
        onlyAppsWithLaunchIntent: true,
      ).timeout(const Duration(seconds: 25));
      
      if (result != null) {
        apps = result;
      }
    } catch (e) {
      return [];
    }

    final listResult = <InstalledAppInfo>[];
    for (final app in apps) {
      try {
        int size = 0;
        final apkPath = app['apkFilePath'] ?? '';
        try {
          if (apkPath.isNotEmpty) {
            size = await File(apkPath).length();
          }
        } catch (_) {}

        listResult.add(InstalledAppInfo._(
          packageName: app['packageName'] ?? '',
          appName: app['appName'] ?? '',
          versionName: app['versionName'] ?? '',
          versionCode: app['versionCode'] ?? 0,
          iconBytes: app['appIcon'] != null ? Uint8List.fromList(List<int>.from(app['appIcon'])) : null,
          sizeBytes: size,
          installedAt: DateTime.fromMillisecondsSinceEpoch(app['installTimeMillis'] ?? 0),
          updatedAt: DateTime.fromMillisecondsSinceEpoch(app['updateTimeMillis'] ?? 0),
          raw: app,
        ));
      } catch (_) {}
    }

    listResult.sort((a, b) => a.appName.toLowerCase().compareTo(b.appName.toLowerCase()));
    return listResult;
  }
}
