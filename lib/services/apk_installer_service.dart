import 'dart:io';
import 'package:flutter/material.dart';
import 'package:playstore_flutter/models/store_app.dart';

class ApkInstallerException implements Exception {
  final String message;
  ApkInstallerException(this.message);
}

class ApkInstallerService {
  static final ApkInstallerService _instance = ApkInstallerService._internal();
  factory ApkInstallerService() => _instance;
  ApkInstallerService._internal();

  /// Verifica se o app já está instalado no dispositivo.
  Future<bool> isInstalled(String packageName) async {
    // TODO: implementar com platform channel ou plugin (ex: device_apps)
    // Placeholder para o build passar:
    return false;
  }

  /// Baixa e instala o APK, ou abre se já estiver instalado.
  Future<void> installOrOpen(
    StoreApp app, {
    required void Function(double progress) onProgress,
  }) async {
    try {
      // TODO: substituir pela lógica real de download + instalação
      // Simulação de progresso para o build compilar:
      for (int i = 1; i <= 10; i++) {
        await Future.delayed(const Duration(milliseconds: 150));
        onProgress(i / 10);
      }
    } catch (e) {
      throw ApkInstallerException(e.toString());
    }
  }
}
