import 'package:flutter/material.dart';

/// Paleta de cores centralizada do app (compatibilidade total com telas antigas e novas)

// Cores de compatibilidade globais (usadas por fragments e listas antigas)
const Color appDividerColor = Color(0xFFDADADA);
const Color appTextColorPrimary = Color(0xFF212121);
const Color appTextColorSecondary = Color(0xFF5A5C5E);
const Color appLayout_background = Color(0xFFf8f8f8);

/// Classe de compatibilidade para telas que chamam AppleColors.xxx
class AppleColors {
  AppleColors._();

  static const Color background = Color(0xFFFFFFFF);
  static const Color backgroundSecondary = Color(0xFFF2F2F7);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF5A5C5E);
  static const Color accentBlue = Color(0xFF0071E3);
  static const Color pillNeutralBackground = Color(0xFFE8E8ED);
  static const Color divider = Color(0xFFDADADA);
  static const Color appDividerColor = Color(0xFFDADADA);
}

// Light Theme Colors originais do seu escopo
const iconColorPrimary = Color(0xFFFFFFFF);
const iconColorSecondary = Color(0xFFA8ABAD);
const appWhite = Color(0xFFFFFFFF);
const appShadowColor = Color(0x95E9EBF0);
const appColorPrimaryLight = Color(0xFFF9FAFF);
const appSecondaryBackgroundColor = Color(0xFF131d25);

// Dark Theme Colors originais do seu escopo
const appBackgroundColorDark = Color(0xFF131d25);
const cardBackgroundBlackDark = Color(0xFF1D2939);
const color_primary_black = Color(0xFF131d25);
const appColorPrimaryDarkLight = Color(0xFFF9FAFF);
const iconColorPrimaryDark = Color(0xFF212121);
const iconColorSecondaryDark = Color(0xFFA8ABAD);
const appShadowColorDark = Color(0x1A3E3942);
