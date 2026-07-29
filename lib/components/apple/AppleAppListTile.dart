import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:playstore_flutter/model/PSModel.dart';
import 'package:playstore_flutter/utils/AppWidget.dart';
import 'package:playstore_flutter/utils/AppleColors.dart';
import 'package:playstore_flutter/widgets/install_button.dart';

/// Item de lista minimalista no padrão App Store, com expansão inline.
///
/// Ao tocar no corpo do card (ícone, título ou subtítulo), o item se
/// expande na própria posição da lista - sem navegar para uma tela de
/// detalhes separada - revelando descrição completa, tamanho do arquivo
/// e categoria. Tocar novamente recolhe.
///
/// O botão "Instalar" continua com sua própria área de toque e nunca
/// aciona a expansão/recolhimento do card.
class AppleAppListTile extends StatefulWidget {
  final PSGameModel data;

  const AppleAppListTile({super.key, required this.data});

  @override
  State<AppleAppListTile> createState() => _AppleAppListTileState();
}

class _AppleAppListTileState extends State<AppleAppListTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final category = (data.categories?.isNotEmpty ?? false) ? data.categories!.join(', ') : (data.subTitle ?? '');
    final sizeLabel = (data.appSize ?? 0) > 0 ? '${data.appSize!.toStringAsFixed(1)} MB' : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Ícone "squircle": cantos arredondados de 12px, como os
                // ícones de app da Apple.
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: commonCacheImageWidget(data.imgLogo ?? data.imgMain, height: 56, width: 56, fit: BoxFit.cover),
                ),
                14.width,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        data.title ?? '',
                        style: boldTextStyle(color: AppleColors.textPrimary, size: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      2.height,
                      Text(
                        category.isNotEmpty ? category : 'App',
                        style: secondaryTextStyle(color: AppleColors.textSecondary, size: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                12.width,
                InstallButton(app: data, size: InstallButtonSize.small),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          child: _expanded ? _buildExpandedDetails(data, category, sizeLabel) : SizedBox(width: double.infinity),
        ),
      ],
    );
  }

  Widget _buildExpandedDetails(PSGameModel data, String category, String? sizeLabel) {
    return Padding(
      padding: EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            data.displayDescription,
            style: primaryTextStyle(color: AppleColors.textPrimary, size: 13),
          ),
          12.height,
          Wrap(
            spacing: 20,
            runSpacing: 8,
            children: [
              if (sizeLabel != null) _detailChip(label: 'Tamanho', value: sizeLabel),
              if (category.isNotEmpty) _detailChip(label: 'Categoria', value: category),
              if ((data.developer ?? '').isNotEmpty) _detailChip(label: 'Desenvolvedor', value: data.developer!),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailChip({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label.toUpperCase(), style: secondaryTextStyle(color: AppleColors.textSecondary, size: 10)),
        2.height,
        Text(value, style: boldTextStyle(color: AppleColors.textPrimary, size: 12)),
      ],
    );
  }
}
