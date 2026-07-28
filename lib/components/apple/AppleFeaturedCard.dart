import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:playstore_flutter/model/PSModel.dart';
import 'package:playstore_flutter/utils/AppWidget.dart';
import 'package:playstore_flutter/utils/AppleColors.dart';

/// Card grande e imersivo usado no carrossel "Recommended for you",
/// no padrão visual da aba Apps da App Store: imagem de fundo em
/// tela cheia (dentro do card), cantos bem arredondados e um rótulo +
/// título + subtítulo limpos sobrepostos na parte inferior, com um
/// leve gradiente para garantir legibilidade sem "sujar" a imagem.
class AppleFeaturedCard extends StatelessWidget {
  final PSGameModel data;
  final VoidCallback? onTap;

  /// Rótulo curto em destaque acima do título (ex: "EM ALTA", "NOVO E
  /// NOTÁVEL"). Opcional - segue o padrão "NOW WITH SIRI" da Apple.
  final String? eyebrow;

  const AppleFeaturedCard({super.key, required this.data, this.onTap, this.eyebrow});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 300,
        height: 340,
        margin: EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: Offset(0, 6)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            commonCacheImageWidget(data.imgMain, fit: BoxFit.cover),
            // Gradiente sutil só na base, para o texto ficar legível sem
            // esconder a arte do app.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: 130,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.55)],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if ((eyebrow ?? '').isNotEmpty) ...[
                    Text(
                      eyebrow!.toUpperCase(),
                      style: boldTextStyle(color: Colors.white, size: 12),
                    ),
                    6.height,
                  ],
                  Text(
                    data.title ?? '',
                    style: boldTextStyle(color: Colors.white, size: 22),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  4.height,
                  if ((data.subTitle ?? '').isNotEmpty)
                    Text(
                      data.subTitle!,
                      style: secondaryTextStyle(color: Colors.white.withOpacity(0.9), size: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
