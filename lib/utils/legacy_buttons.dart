import 'package:flutter/material.dart';

// =====================================================================
// SHIM DE COMPATIBILIDADE
// O Flutter removeu de vez FlatButton e RaisedButton (eram da era
// Material antigo, ~2020). Em vez de editar cada uma das ~20 telas que
// os usam, essas classes recriam a MESMA assinatura antiga por cima dos
// widgets atuais (TextButton / ElevatedButton). Basta importar este
// arquivo nas telas que usam FlatButton/RaisedButton - não precisa
// mudar mais nada nelas.
// =====================================================================

/// Substituto de FlatButton (removido). Delega para TextButton.
class FlatButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final Widget child;
  final Color? color;
  final Color? textColor;
  final Color? disabledColor;
  final Color? disabledTextColor;
  final Color? splashColor;
  final Color? highlightColor;
  final double? minWidth;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final ShapeBorder? shape;
  final MaterialTapTargetSize? materialTapTargetSize;

  const FlatButton({
    super.key,
    required this.onPressed,
    this.onLongPress,
    required this.child,
    this.color,
    this.textColor,
    this.disabledColor,
    this.disabledTextColor,
    this.splashColor,
    this.highlightColor,
    this.minWidth,
    this.height,
    this.padding,
    this.shape,
    this.materialTapTargetSize,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextButton.styleFrom(
      foregroundColor: textColor,
      backgroundColor: color,
      disabledForegroundColor: disabledTextColor,
      disabledBackgroundColor: disabledColor,
      padding: padding,
      shape: shape is OutlinedBorder ? shape as OutlinedBorder : null,
      minimumSize: (minWidth != null || height != null)
          ? Size(minWidth ?? 64, height ?? 36)
          : null,
      tapTargetSize: materialTapTargetSize,
    );
    return TextButton(
      onPressed: onPressed,
      onLongPress: onLongPress,
      style: style,
      child: child,
    );
  }
}

/// Substituto de RaisedButton (removido). Delega para ElevatedButton.
class RaisedButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final Widget child;
  final Color? color;
  final Color? textColor;
  final Color? disabledColor;
  final Color? disabledTextColor;
  final double? elevation;
  final double? highlightElevation;
  final double? disabledElevation;
  final double? minWidth;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final ShapeBorder? shape;
  final MaterialTapTargetSize? materialTapTargetSize;

  const RaisedButton({
    super.key,
    required this.onPressed,
    this.onLongPress,
    required this.child,
    this.color,
    this.textColor,
    this.disabledColor,
    this.disabledTextColor,
    this.elevation,
    this.highlightElevation,
    this.disabledElevation,
    this.minWidth,
    this.height,
    this.padding,
    this.shape,
    this.materialTapTargetSize,
  });

  @override
  Widget build(BuildContext context) {
    final style = ElevatedButton.styleFrom(
      foregroundColor: textColor,
      backgroundColor: color,
      disabledForegroundColor: disabledTextColor,
      disabledBackgroundColor: disabledColor,
      elevation: elevation,
      padding: padding,
      shape: shape is OutlinedBorder ? shape as OutlinedBorder : null,
      minimumSize: (minWidth != null || height != null)
          ? Size(minWidth ?? 64, height ?? 36)
          : null,
      tapTargetSize: materialTapTargetSize,
    );
    return ElevatedButton(
      onPressed: onPressed,
      onLongPress: onLongPress,
      style: style,
      child: child,
    );
  }
}
