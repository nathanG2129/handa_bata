import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CategoryDropdown extends StatelessWidget {
  final String selectedCategory;
  final ValueChanged<String> onCategoryChanged;

  const CategoryDropdown({
    super.key,
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: selectedCategory,
      dropdownColor: const Color(0xFF381c64),
      onChanged: (String? newValue) {
        if (newValue != null) {
          onCategoryChanged(newValue);
        }
      },
      items: <String>['Storm', 'Quake', 'Volcanic', 'Drought', 'Tsunami', 'Flood']
          .map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value, style: GoogleFonts.vt323(color: Colors.white, fontSize: 20)),
        );
      }).toList(),
    );
  }
}