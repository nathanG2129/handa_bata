// lib/helpers/widget_helpers.dart

import 'package:flutter/material.dart';

Widget buildTextFormField({
  required TextEditingController controller,
  required String labelText,
  required String? Function(String?) validator,
  bool obscureText = false,
  bool readOnly = false,
  VoidCallback? onTap,
  Function(String)? onChanged,
}) {
  return TextFormField(
    controller: controller,
    decoration: InputDecoration(
      labelText: labelText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30.0), // Oblong shape
      ),
    ),
    obscureText: obscureText,
    readOnly: readOnly,
    onTap: onTap,
    validator: validator,
    onChanged: onChanged,
  );
}

Widget buildPasswordRequirement({required String text, required bool isValid}) {
  return Row(
    children: [
      Icon(
        isValid ? Icons.check : Icons.close,
        color: isValid ? Colors.green : Colors.red,
      ),
      const SizedBox(width: 8),
      Text(text, style: const TextStyle(color: Colors.white)),
    ],
  );
}