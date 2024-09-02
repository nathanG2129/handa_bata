// lib/helpers/date_helpers.dart
import 'package:flutter/material.dart';

Future<void> selectDate(BuildContext context, TextEditingController controller) async {
  final DateTime? picked = await showDatePicker(
    context: context,
    initialDate: DateTime.now(),
    firstDate: DateTime(1900),
    lastDate: DateTime.now(),
  );
  if (picked != null) {
    controller.text = "${picked.toLocal()}".split(' ')[0];
  }
}