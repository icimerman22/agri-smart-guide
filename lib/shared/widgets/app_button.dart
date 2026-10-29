import 'package:flutter/material.dart';

enum AppButtonVariant { primary, secondary }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
  });

  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final iconWidget = icon == null ? null : Icon(icon);

    if (variant == AppButtonVariant.secondary) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: iconWidget,
        label: Text(text),
      );
    }

    return FilledButton.icon(
      onPressed: onPressed,
      icon: iconWidget,
      label: Text(text),
    );
  }
}
