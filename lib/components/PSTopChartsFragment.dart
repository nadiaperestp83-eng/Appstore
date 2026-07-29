import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:playstore_flutter/components/apple/AppleAppListTile.dart';
import 'package:playstore_flutter/components/apple/AppleGroupedCard.dart';
import 'package:playstore_flutter/model/PSModel.dart';
import 'package:playstore_flutter/utils/AppleColors.dart';

/// Fragmento "Top charts" 100% orientado a dados reais.
///
/// Antes lia direto de um mock global (`getGameList`), inclusive com um
/// índice fixo errado quando reaproveitado na aba Apps (sempre mostrava os
/// dados de Games). Agora recebe a busca real (Aptoide) já pronta via
/// [sectionsFuture] e o [sectionOrder] com o nome/ordem dos chips - nenhuma
/// tela precisa mais expor um mock pra esse componente funcionar.
///
/// Unificado visualmente com o resto do app: chips em azul Apple, lista
/// dentro de um card branco agrupado ([AppleGroupedCard]) sobre o fundo
/// cinza (ver PSAppsScreen/PSGamesScreen), e o mesmo item expansível
/// inline ([AppleAppListTile]) usado nas outras seções - sem navegar pra
/// tela de detalhe separada.
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
            child: Text('Não foi possível carregar o Top charts agora.', style: secondaryTextStyle(color: AppleColors.textSecondary)),
          );
        }

        final sections = snapshot.data ?? {};
        final availableNames = widget.sectionOrder.where((n) => sections.containsKey(n)).toList();
        if (availableNames.isEmpty) {
          return Container(
            padding: EdgeInsets.symmetric(vertical: 32, horizontal: 16),
            alignment: Alignment.center,
            child: Text('Nenhum item encontrado.', style: secondaryTextStyle(color: AppleColors.textSecondary)),
          );
        }

        _selectedSection ??= availableNames.first;
        final currentList = sections[_selectedSection] ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                  return InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      _selectedSection = name;
                      setState(() {});
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: selected ? AppleColors.accentBlue : AppleColors.background,
                        border: Border.all(color: selected ? AppleColors.accentBlue : AppleColors.divider),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(name, style: primaryTextStyle(color: selected ? Colors.white : AppleColors.textPrimary)),
                    ),
                  ).paddingOnly(top: 14, left: 8, right: 8);
                },
              ),
            ),
            16.height,
            currentList.isNotEmpty
                ? AppleGroupedCard(
                    dividerIndent: 84,
                    children: currentList.map((item) => AppleAppListTile(data: item)).toList(),
                  )
                : Padding(
                    padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    child: Text('Nenhum item encontrado em "$_selectedSection".', style: secondaryTextStyle(color: AppleColors.textSecondary)),
                  ),
          ],
        );
      },
    );
  }
}
