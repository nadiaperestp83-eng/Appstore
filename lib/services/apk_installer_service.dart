import 'package:flutter/material.dart';
import '../models/store_app.dart';
import '../services/apk_installer_service.dart';

class InstallButton extends StatefulWidget {
  final StoreApp app;
  final ApkInstallerService? installerService;

  const InstallButton({
    Key? key,
    required this.app,
    this.installerService,
  }) : super(key: key);

  @override
  State<InstallButton> createState() => _InstallButtonState();
}

class _InstallButtonState extends State<InstallButton> {
  late final ApkInstallerService _installer;
  bool _isLoading = false;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _installer = widget.installerService ?? ApkInstallerService();
  }

  @override
  void dispose() {
    if (widget.installerService == null) {
      _installer.dispose();
    }
    super.dispose();
  }

  Future<void> _handleInstall() async {
    setState(() {
      _isLoading = true;
      _progress = 0.0;
    });

    try {
      await _installer.installOrOpen(
        widget.app,
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _progress = progress;
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: ${e.toString().replaceAll('ApkInstallerException: ', '')}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _progress = 0.0;
        });
      }
    }
  }

  @override
  Widget build(context) {
    final themeDividerColor = Theme.of(context).dividerColor;
    const primaryColor = Colors.green;

    return InkWell(
      onTap: _isLoading ? null : _handleInstall,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: _isLoading ? Colors.grey.shade300 : primaryColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: _isLoading
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      value: _progress > 0 ? _progress : null,
                      strokeWidth: 2,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _progress > 0 ? '${(_progress * 100).toStringAsFixed(0)}%' : 'Baixando...',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              )
            : const Text(
                'Install',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
      ),
    );
  }
}
