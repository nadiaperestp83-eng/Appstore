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
  final ApplicationInfo _raw;

  InstalledAppInfo._({
    required this.packageName,
    required this.appName,
    required this.versionName,
    required this.versionCode,
    required this.iconBytes,
    required this.sizeBytes,
    required this.installedAt,
    required this.updatedAt,
    required ApplicationInfo raw,
  }) : _raw = raw;

  Future<bool?> open() => FlutterDeviceApps.openApp(packageName);
}

class InstalledAppsService {
  Future<List<InstalledAppInfo>> listLauncherApps() async {
    if (!Platform.isAndroid) return [];

    List<ApplicationInfo> apps = [];
    try {
      final result = await FlutterDeviceApps.listApps(
        includeIcons: true,
        includeSystem: false,
        onlyLaunchable: true,
      ).timeout(const Duration(seconds: 25));
      
      if (result.isNotEmpty) {
        apps = result;
      }
    } catch (e) {
      return [];
    }

    final listResult = <InstalledAppInfo>[];
    for (final app in apps) {
      try {
        int size = 0;
        try {
          if (app.apkPath.isNotEmpty) {
            size = await File(app.apkPath).length();
          }
        } catch (_) {}

        listResult.add(InstalledAppInfo._(
          packageName: app.packageName,
          appName: app.appName,
          versionName: app.versionName ?? '',
          versionCode: app.versionCode,
          iconBytes: app.iconBytes,
          sizeBytes: size,
          installedAt: DateTime.fromMillisecondsSinceEpoch(app.installTimeMillis),
          updatedAt: DateTime.fromMillisecondsSinceEpoch(app.updateTimeMillis),
          raw: app,
        ));
      } catch (_) {}
    }

    listResult.sort((a, b) => a.appName.toLowerCase().compareTo(b.appName.toLowerCase()));
    return listResult;
  }
}
