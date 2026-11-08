import 'package:flutter/material.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.labelText,
    this.hintText,
    this.controller,
    this.onChanged,
    this.icon,
    this.validator,
    this.obscureText = false,
    this.keyboardType,
    this.enabled = true,
  });

  final String? labelText;
  final String? hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final IconData? icon;
  final FormFieldValidator<String>? validator;
  final bool obscureText;
  final TextInputType? keyboardType;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      validator: validator,
      obscureText: obscureText,
      keyboardType: keyboardType,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: icon == null ? null : Icon(icon),
      ),
    );
  }
}
