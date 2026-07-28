import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:playstore_flutter/services/installed_apps_service.dart';
import 'package:playstore_flutter/utils/AppColors.dart';
import 'package:playstore_flutter/utils/AppWidget.dart';

/// Aba "Installed": lista real dos apps com ícone no launcher (mesmo
/// critério da Play Store - sem apps de sistema), vindos direto do
/// aparelho via `device_apps`. Nada aqui é mockado.
class PSInstalledFragment extends StatefulWidget {
  @override
  PSInstalledFragmentState createState() => PSInstalledFragmentState();
}

enum _SortBy { name, size }

class PSInstalledFragmentState extends State<PSInstalledFragment> {
  final InstalledAppsService _service = InstalledAppsService();
  late final Future<List<InstalledAppInfo>> _appsFuture;

  _SortBy _sortBy = _SortBy.name;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _appsFuture = _service.listLauncherApps();
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  List<InstalledAppInfo> _applyFilters(List<InstalledAppInfo> apps) {
    var list = apps;
    if (_query.trim().isNotEmpty) {
      final q = _query.toLowerCase();
      list = list.where((a) => a.appName.toLowerCase().contains(q) || a.packageName.toLowerCase().contains(q)).toList();
    }
    list = [...list];
    if (_sortBy == _SortBy.name) {
      list.sort((a, b) => a.appName.toLowerCase().compareTo(b.appName.toLowerCase()));
    } else {
      list.sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<InstalledAppInfo>>(
      future: _appsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Não foi possível ler os apps instalados agora.', style: secondaryTextStyle()),
          );
        }

        final all = snapshot.data ?? [];
        if (all.isEmpty) {
          return Center(child: Text('Nenhum app encontrado no aparelho.', style: secondaryTextStyle()));
        }

        final apps = _applyFilters(all);

        return Column(
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Buscar nos apps instalados',
                  prefixIcon: Icon(Icons.search),
                  filled: true,
                  fillColor: appDividerColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${apps.length} apps', style: secondaryTextStyle()),
                  Row(
                    children: [
                      Text('Ordenar: ', style: secondaryTextStyle()),
                      DropdownButton<_SortBy>(
                        value: _sortBy,
                        underline: SizedBox(),
                        items: [
                          DropdownMenuItem(value: _SortBy.name, child: Text('Nome', style: primaryTextStyle(size: 13))),
                          DropdownMenuItem(value: _SortBy.size, child: Text('Tamanho', style: primaryTextStyle(size: 13))),
                        ],
                        onChanged: (v) => setState(() => _sortBy = v ?? _SortBy.name),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.symmetric(vertical: 8),
                itemCount: apps.length,
                separatorBuilder: (context, index) => Divider(height: 1, indent: 76),
                itemBuilder: (context, index) => _InstalledAppRow(app: apps[index]),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _InstalledAppRow extends StatelessWidget {
  final InstalledAppInfo app;

  const _InstalledAppRow({required this.app});

  String get _sizeLabel {
    if (app.sizeBytes <= 0) return '';
    final mb = app.sizeBytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)}MB';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          app.iconBytes != null
              ? Image.memory(app.iconBytes!, height: 48, width: 48, fit: BoxFit.cover).cornerRadiusWithClipRRect(10)
              : Container(height: 48, width: 48, decoration: boxDecoration(bgColor: appDividerColor, radius: 10), child: Icon(Icons.android)),
          12.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(app.appName, style: boldTextStyle(size: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                2.height,
                Text(
                  'v${app.versionName.isNotEmpty ? app.versionName : app.versionCode}${_sizeLabel.isNotEmpty ? ' · $_sizeLabel' : ''}',
                  style: secondaryTextStyle(size: 12),
                ),
              ],
            ),
          ),
          12.width,
          OutlinedButton(
            onPressed: () => app.open(),
            child: Text('Abrir', style: secondaryTextStyle(size: 12)),
          ),
        ],
      ),
    );
  }
}
