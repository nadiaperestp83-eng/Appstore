import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:playstore_flutter/model/PSModel.dart';
import 'package:playstore_flutter/screens/PSDetailScreen.dart';
import 'package:playstore_flutter/utils/AppWidget.dart';
import 'package:playstore_flutter/utils/PSColor.dart';
import 'package:playstore_flutter/widgets/install_button.dart';

/// Fragmento "Top charts" 100% orientado a dados reais.
///
/// Antes lia direto de um mock global (`getGameList`), inclusive com um
/// índice fixo errado quando reaproveitado na aba Apps (sempre mostrava os
/// dados de Games). Agora recebe a busca real (Aptoide) já pronta via
/// [sectionsFuture] e o [sectionOrder] com o nome/ordem dos chips - nenhuma
/// tela precisa mais expor um mock pra esse componente funcionar.
class PSTopChartsFragment extends StatefulWidget {
  static String tag = '/TopCharts';

  /// Busca real (Aptoide) das seções: nome da categoria -> lista de apps.
  final Future<Map<String, List<PSGameModel>>> sectionsFuture;

  /// Ordem em que os chips de categoria devem aparecer.
  final List<String> sectionOrder;

  const PSTopChartsFragment({
    super.key,
    required this.sectionsFuture,
    required this.sectionOrder,
  });

  @override
  PSTopChartsFragmentState createState() => PSTopChartsFragmentState();
}

class PSTopChartsFragmentState extends State<PSTopChartsFragment> {
  String? _selectedSection;

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, List<PSGameModel>>>(
      future: widget.sectionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: EdgeInsets.symmetric(vertical: 32),
            alignment: Alignment.center,
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Container(
            padding: EdgeInsets.symmetric(vertical: 32, horizontal: 16),
            alignment: Alignment.center,
            child: Text('Não foi possível carregar o Top charts agora.', style: secondaryTextStyle()),
          );
        }

        final sections = snapshot.data ?? {};
        final availableNames = widget.sectionOrder.where((n) => sections.containsKey(n)).toList();
        if (availableNames.isEmpty) {
          return Container(
            padding: EdgeInsets.symmetric(vertical: 32, horizontal: 16),
            alignment: Alignment.center,
            child: Text('Nenhum item encontrado.', style: secondaryTextStyle()),
          );
        }

        _selectedSection ??= availableNames.first;
        final currentList = sections[_selectedSection] ?? [];

        return Column(
          children: [
            Container(
              height: 55,
              child: ListView.builder(
                padding: EdgeInsets.only(left: 8, right: 8),
                scrollDirection: Axis.horizontal,
                shrinkWrap: true,
                itemCount: availableNames.length,
                itemBuilder: (context, index) {
                  final name = availableNames[index];
                  final selected = name == _selectedSection;
                  return FlatButton(
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: selected ? psColorGreen : Colors.grey[400]!),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    color: selected ? Colors.green[50] : null,
                    highlightColor: Colors.green[100],
                    onPressed: () {
                      _selectedSection = name;
                      setState(() {});
                    },
                    child: Text(name, style: primaryTextStyle(color: selected ? psColorGreen : null)),
                  ).paddingOnly(top: 14, left: 8, right: 8);
                },
              ),
            ),
            currentList.isNotEmpty
                ? ListView.builder(
                    physics: NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: currentList.length,
                    itemBuilder: (BuildContext context, int index) {
                      final item = currentList[index];
                      return Container(
                        child: Column(
                          children: [
                            16.height,
                            Row(
                              children: [
                                Row(
                                  children: [
                                    8.width,
                                    commonCacheImageWidget(item.imgLogo, height: 50, width: 60, fit: BoxFit.cover).cornerRadiusWithClipRRect(10),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item.title ?? '', style: boldTextStyle()).paddingOnly(left: 16),
                                        if ((item.subTitle ?? '').isNotEmpty)
                                          Text(item.subTitle!, style: secondaryTextStyle(), overflow: TextOverflow.ellipsis).paddingOnly(left: 16),
                                        Row(
                                          children: [
                                            Text((item.rating ?? 0).toStringAsFixed(1), style: secondaryTextStyle()).paddingOnly(left: 16),
                                            Icon(Icons.star, size: 10),
                                            if ((item.appSize ?? 0) > 0) Text('${item.appSize!.toStringAsFixed(1)}MB').paddingOnly(left: 16),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ).onTap(() {
                                  PSDetailScreen(data: item).launch(context);
                                }).expand(),
                                InstallButton(app: item, size: InstallButtonSize.small),
                                8.width,
                              ],
                            ),
                          ],
                        ).paddingOnly(left: 16),
                      );
                    },
                  )
                : Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text('Nenhum item encontrado em "$_selectedSection".', style: secondaryTextStyle()),
                  ),
          ],
        );
      },
    );
  }
}
