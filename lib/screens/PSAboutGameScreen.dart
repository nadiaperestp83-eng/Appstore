import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:playstore_flutter/model/PSModel.dart';
import 'package:playstore_flutter/utils/AppWidget.dart';
import 'package:playstore_flutter/utils/PSColor.dart';

/// Tela cheia "About this game/app". 100% orientada a dados reais do
/// [PSGameModel] selecionado - nenhum texto fixo de exemplo. Campos que a
/// nossa fonte (Aptoide/F-Droid/GitHub) genuinamente não fornece (rating
/// etário, política de anúncios, changelog, data de lançamento) foram
/// removidos em vez de preenchidos com valores inventados.
class PSAboutGameScreen extends StatefulWidget {
  static String tag = '/PSAboutGameScreen';
  final PSGameModel? data;

  PSAboutGameScreen({this.data});

  @override
  PSAboutGameScreenState createState() => PSAboutGameScreenState();
}

class PSAboutGameScreenState extends State<PSAboutGameScreen> {
  @override
  Widget build(BuildContext context) {
    final data = widget.data!;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            commonCacheImageWidget(data.imgLogo ?? data.imgMain, height: 40, width: 40, fit: BoxFit.cover).paddingOnly(right: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data.title ?? '', style: boldTextStyle(), overflow: TextOverflow.ellipsis),
                Text('Details', style: boldTextStyle()),
              ],
            ).expand(),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('About this app', style: boldTextStyle()),
            8.height,
            Text(data.displayDescription, style: secondaryTextStyle()),
            if ((data.categories ?? []).isNotEmpty) ...[
              16.height,
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: data.categories!
                    .map((c) => Container(
                          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: boxDecoration(color: Colors.grey, radius: 16),
                          child: Text(c, style: secondaryTextStyle(size: 12)),
                        ))
                    .toList(),
              ),
            ],
            16.height,
            Divider(thickness: 1),
            8.height,
            Text('App info', style: boldTextStyle()),
            16.height,
            _infoRow('Developer', (data.developer ?? '').isNotEmpty ? data.developer! : 'Não informado'),
            16.height,
            _infoRow('Version', (data.version ?? '').isNotEmpty ? data.version! : 'Não informado'),
            16.height,
            _infoRow('Download size', (data.appSize ?? 0) > 0 ? '${data.appSize!.toStringAsFixed(1)} MB' : 'Não informado'),
            16.height,
            _infoRow('Downloads', (data.downloads ?? 0) > 0 ? _formatDownloads(data.downloads!) : 'Não informado'),
            16.height,
            _infoRow('Source', (data.preferredRepoLabel ?? '').isNotEmpty ? data.preferredRepoLabel! : 'Não informado'),
            if (data.hasMultipleSources) ...[
              16.height,
              _infoRow('Available in', '${data.availableSourceOptions!.length} sources'),
            ],
            32.height,
          ],
        ),
      ).paddingOnly(left: 16, top: 16, right: 16),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        Text(label, style: secondaryTextStyle()).expand(),
        Text(value, style: secondaryTextStyle(), textAlign: TextAlign.right),
      ],
    );
  }

  String _formatDownloads(int downloads) {
    if (downloads >= 1000000) return '${(downloads / 1000000).toStringAsFixed(1)}M+';
    if (downloads >= 1000) return '${(downloads / 1000).toStringAsFixed(0)}K+';
    return '$downloads+';
  }
}
