import 'package:flutter/material.dart';

/// Paleta de cores no padrão visual da App Store da Apple.
/// Usada exclusivamente pela nova experiência da aba "Apps"
/// (ver [PSAppsScreen], `AppleFeaturedCard` e `AppleAppListTile`).
class AppleColors {
  AppleColors._();

  /// Fundo geral: branco puro.
  static const Color background = Color(0xFFFFFFFF);

  /// Fundo alternativo, cinza claro suave (agrupamentos, chips) - igual ao
  /// CupertinoColors.systemGroupedBackground do iOS.
  static const Color backgroundSecondary = Color(0xFFF2F2F7);

  /// Título / texto principal: preto profundo.
  static const Color textPrimary = Color(0xFF1D1D1F);

  /// Subtítulo / texto secundário: cinza médio.
  static const Color textSecondary = Color(0xFF86868B);

  /// Azul clássico da Apple, usado em botões e links de ação.
  static const Color accentBlue = Color(0xFF0071E3);

  /// Fundo em pílula cinza-claro para botões de estado neutro (ex: "Aberto").
  static const Color pillNeutralBackground = Color(0xFFE8E8ED);

  /// Divisor sutil entre linhas de lista.
  static const Color divider = Color(0xFFE5E5EA);

  /// Compatibilidade com telas legadas (ex: PSBookScreen).
  static const Color appDividerColor = Color(0xFFE5E5EA);
}
