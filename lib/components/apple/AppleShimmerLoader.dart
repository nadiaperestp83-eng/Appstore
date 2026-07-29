import 'package:flutter/material.dart';
import 'package:playstore_flutter/utils/AppleColors.dart';

/// Skeleton loader "shimmer" cinza suave, sem depender de pacote externo:
/// anima uma faixa de brilho passando sobre blocos cinza no formato de uma
/// linha real de app (ícone quadrado + duas linhas de texto), usado
/// enquanto os dados reais (Aptoide/F-Droid/GitHub) de uma categoria ainda
/// não chegaram - garante uma transição fluida em vez de um
/// CircularProgressIndicator seco no meio da tela.
class AppleShimmerLoader extends StatefulWidget {
  final int itemCount;

  const AppleShimmerLoader({Key? key, this.itemCount = 6}) : super(key: key);

  @override
  State<AppleShimmerLoader> createState() => _AppleShimmerLoaderState();
}

class _AppleShimmerLoaderState extends State<AppleShimmerLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.white.withOpacity(0.08) : AppleColors.backgroundSecondary;
    final highlightColor = isDark ? Colors.white.withOpacity(0.20) : Colors.white;

    return Container(
      decoration: BoxDecoration(color: AppleColors.background, borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: List.generate(widget.itemCount, (index) {
          final isLast = index == widget.itemCount - 1;
          return Container(
            decoration: isLast
                ? null
                : BoxDecoration(border: Border(bottom: BorderSide(color: AppleColors.divider, width: 1))),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _shimmerBlock(width: 48, height: 48, radius: 12, baseColor: baseColor, highlightColor: highlightColor),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _shimmerBlock(width: double.infinity, height: 13, radius: 6, baseColor: baseColor, highlightColor: highlightColor, widthFactor: 0.62),
                      const SizedBox(height: 8),
                      _shimmerBlock(width: double.infinity, height: 11, radius: 6, baseColor: baseColor, highlightColor: highlightColor, widthFactor: 0.38),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                _shimmerBlock(width: 64, height: 26, radius: 8, baseColor: baseColor, highlightColor: highlightColor),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _shimmerBlock({
    required double width,
    required double height,
    required double radius,
    required Color baseColor,
    required Color highlightColor,
    double widthFactor = 1.0,
  }) {
    return FractionallySizedBox(
      widthFactor: width.isFinite ? 1.0 : widthFactor,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = _controller.value;
          return ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (bounds) {
              return LinearGradient(
                colors: [baseColor, highlightColor, baseColor],
                stops: const [0.35, 0.5, 0.65],
                begin: Alignment(-3 + t * 6, 0),
                end: Alignment(-1 + t * 6, 0),
              ).createShader(bounds);
            },
            child: Container(
              width: width.isFinite ? width : null,
              height: height,
              decoration: BoxDecoration(color: baseColor, borderRadius: BorderRadius.circular(radius)),
            ),
          );
        },
      ),
    );
  }
}
