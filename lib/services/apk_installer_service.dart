import 'dart:io';
import 'package:flutter/material.dart';
import '../models/store_app.dart';

class ApkInstallerException implements Exception {
  final String message;
  ApkInstallerException(this.message);

  @override
  String toString() => 'ApkInstallerException: $message';
}

class ApkInstallerService {
  bool _disposed = false;

  /// Instala ou abre o app. Implemente sua lógica real aqui.
  Future<void> installOrOpen(
    StoreApp app, {
    required void Function(double progress) onProgress,
  }) async {
    if (_disposed) return;

    try {
      // Simulação de download com progresso
      // Substitua pela sua lógica real de download + instalação
      for (int i = 1; i <= 10; i++) {
        if (_disposed) return;
        await Future.delayed(const Duration(milliseconds: 200));
        onProgress(i / 10);
      }

      // Aqui você coloca a instalação real do APK
      // Exemplo: usar intent do Android, plugin open_file, etc.
      debugPrint('Instalando ${app.name}...');
    } catch (e) {
      throw ApkInstallerException(e.toString());
    }
  }

  void dispose() {
    _disposed = true;
  }
}
