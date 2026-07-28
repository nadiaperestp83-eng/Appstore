import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:playstore_flutter/model/PSModel.dart';
import 'package:playstore_flutter/services/installed_apps_service.dart';
import 'package:playstore_flutter/utils/AppColors.dart';
import 'package:playstore_flutter/utils/AppWidget.dart';
import 'package:playstore_flutter/utils/PSColor.dart';
import 'package:playstore_flutter/utils/PSDataProvider.dart';
import 'package:playstore_flutter/widgets/install_button.dart';

/// Aba "Updates": compara os apps REAIS instalados no aparelho com o nosso
/// catálogo real (F-Droid + GitHub) e mostra quais têm versão mais nova
/// disponível. Só conseguimos detectar isso pra apps cujo package name bate
/// com algo do nosso catálogo - a imensa maioria dos apps instalados (Play
/// Store, apps de sistema etc.) simplesmente não tem como ser comparada, já
/// que não temos acesso ao catálogo dessas outras lojas.
class PSUpdatesFragments extends StatefulWidget {
  @override
  PSUpdatesFragmentsState createState() => PSUpdatesFragmentsState();
}

class _UpdateEntry {
  final InstalledAppInfo installed;
  final PSGameModel catalogApp;
  _UpdateEntry(this.installed, this.catalogApp);
}

class PSUpdatesFragmentsState extends State<PSUpdatesFragments> {
  late final Future<_UpdatesData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _load();
  }

  Future<_UpdatesData> _load() async {
    final results = await Future.wait([
      InstalledAppsService().listLauncherApps(),
      getCatalogByPackageName(), // F-Droid oficial + repos GitHub configurados
    ]);
    final installed = results[0] as List<InstalledAppInfo>;
    final catalog = results[1] as Map<String, PSGameModel>;

    final pending = <_UpdateEntry>[];
    for (final app in installed) {
      final catalogApp = catalog[app.packageName];
      if (catalogApp == null) continue;
      final catalogVersion = catalogApp.versionCode ?? 0;
      if (catalogVersion > app.versionCode) {
        pending.add(_UpdateEntry(app, catalogApp));
      }
    }

    final recentlyUpdated = [...installed]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return _UpdatesData(pending: pending, recentlyUpdated: recentlyUpdated.take(15).toList());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_UpdatesData>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Não foi possível verificar atualizações agora.', style: secondaryTextStyle()),
          );
        }

        final data = snapshot.data!;

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              16.height,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      data.pending.isEmpty ? 'Tudo atualizado' : '${data.pending.length} atualizações pendentes',
                      style: boldTextStyle(size: 18),
                    ).paddingOnly(left: 16),
                  ),
                  if (data.pending.isNotEmpty)
                    TextButton(
                      onPressed: () => _updateAll(data.pending),
                      child: Text('Update all', style: primaryTextStyle(color: psColorGreen)),
                    ).paddingOnly(right: 8),
                ],
              ),
              Text(
                'Comparado com o catálogo (F-Droid + GitHub). Apps de outras lojas não são checados.',
                style: secondaryTextStyle(size: 12),
              ).paddingOnly(left: 16, right: 16),
              8.height,
              Divider(),
              if (data.pending.isNotEmpty) ...[
                ...data.pending.map((e) => _UpdateRow(entry: e)),
                Divider(),
              ],
              16.height,
              Text('Atualizados recentemente', style: boldTextStyle(size: 16)).paddingOnly(left: 16),
              8.height,
              if (data.recentlyUpdated.isEmpty)
                Text('Nada por aqui ainda.', style: secondaryTextStyle()).paddingOnly(left: 16)
              else
                ...data.recentlyUpdated.map((app) => _RecentRow(app: app)),
              24.height,
            ],
          ),
        );
      },
    );
  }

  void _updateAll(List<_UpdateEntry> pending) {
    // O Android exige confirmação manual em cada instalação (não existe
    // "atualizar tudo" silencioso sem root/MDM) - por isso disparamos só a
    // primeira e avisamos, em vez de fingir um bulk-update que não existe.
    toast('Abrindo atualização de "${pending.first.catalogApp.title}". Confirme e toque em Atualizar nos próximos.');
    triggerInstall(pending.first.catalogApp);
  }
}

class _UpdatesData {
  final List<_UpdateEntry> pending;
  final List<InstalledAppInfo> recentlyUpdated;
  _UpdatesData({required this.pending, required this.recentlyUpdated});
}

class _UpdateRow extends StatelessWidget {
  final _UpdateEntry entry;
  const _UpdateRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          commonCacheImageWidget(entry.catalogApp.imgLogo, height: 48, width: 48, fit: BoxFit.cover).cornerRadiusWithClipRRect(10),
          12.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.installed.appName, style: boldTextStyle(size: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                2.height,
                Text(
                  '${entry.installed.versionName} → ${entry.catalogApp.version ?? ''}',
                  style: secondaryTextStyle(size: 12),
                ),
              ],
            ),
          ),
          12.width,
          InstallButton(app: entry.catalogApp, size: InstallButtonSize.small),
        ],
      ),
    );
  }
}

class _RecentRow extends StatelessWidget {
  final InstalledAppInfo app;
  const _RecentRow({required this.app});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          app.iconBytes != null
              ? Image.memory(app.iconBytes!, height: 40, width: 40, fit: BoxFit.cover).cornerRadiusWithClipRRect(10)
              : Container(height: 40, width: 40, decoration: boxDecoration(bgColor: appDividerColor, radius: 10), child: Icon(Icons.android, size: 20)),
          12.width,
          Expanded(
            child: Text(app.appName, style: primaryTextStyle(size: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          Text('v${app.versionName.isNotEmpty ? app.versionName : app.versionCode}', style: secondaryTextStyle(size: 12)),
        ],
      ),
    );
  }
}
