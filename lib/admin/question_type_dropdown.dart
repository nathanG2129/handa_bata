import 'package:flutter/material.dart';

class QuestionTypeDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String?> onChanged;

  const QuestionTypeDropdown({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      items: ['Identification', 'Multiple Choice', 'Matching Type', 'Fill in the Blanks']
          .map((type) => DropdownMenuItem(value: type, child: Text(type)))
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(labelText: 'Question Type'),
    );
  }
}