import 'package:flutter/material.dart';
import 'package:playstore_flutter/utils/AppleColors.dart';

/// Card branco arredondado com borda fina, agrupando uma lista de itens
/// (ex: [AppleAppListTile]) com divisores sutis SÓ entre eles - o último
/// item não ganha divisor, porque a borda do próprio card já fecha o
/// grupo. Mesmo padrão visual usado em Settings e no novo sheet de perfil.
class AppleGroupedCard extends StatelessWidget {
  final List<Widget> children;

  /// Recuo do divisor a partir da esquerda - use um valor que alinhe com
  /// o fim do ícone/leading do item (ex: 84 para [AppleAppListTile], que
  /// tem 16 de padding + 56 de ícone + 14 de espaçamento). Use 0 para um
  /// divisor de ponta a ponta.
  final double dividerIndent;

  final EdgeInsets margin;

  const AppleGroupedCard({
    super.key,
    required this.children,
    this.dividerIndent = 16,
    this.margin = const EdgeInsets.symmetric(horizontal: 16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: AppleColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppleColors.divider, width: 0.6),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1) Divider(height: 1, thickness: 1, color: AppleColors.divider, indent: dividerIndent),
          ],
        ],
      ),
    );
  }
}
