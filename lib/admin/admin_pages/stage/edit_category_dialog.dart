import 'package:flutter/material.dart';
import 'package:handabatamae/services/stage_service.dart';
import 'package:google_fonts/google_fonts.dart';

class EditCategoryDialog extends StatefulWidget {
  final String language;
  final String categoryId;
  final String initialName;
  final String initialDescription;
  final String initialColor;
  final int initialPosition;

  const EditCategoryDialog({
    super.key,
    required this.language,
    required this.categoryId,
    required this.initialName,
    required this.initialDescription,
    required this.initialColor,
    required this.initialPosition,
  });

  @override
  EditCategoryDialogState createState() => EditCategoryDialogState();
}

class EditCategoryDialogState extends State<EditCategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  final StageService _stageService = StageService();
  late String _name;
  late String _description;

  @override
  void initState() {
    super.initState();
    _name = widget.initialName;
    _description = widget.initialDescription;
  }

  void _saveCategory() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      await _stageService.updateCategory(widget.language, widget.categoryId, {
        'name': _name,
        'description': _description,
        'color': widget.initialColor,
        'position': widget.initialPosition,
      });

      if (!mounted) return;

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white, // Set dialog background to white
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0.0), // Square corners
        side: const BorderSide(color: Colors.black, width: 2.0), // Black and slightly thick border
      ),
      child: IntrinsicHeight(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20.0), // Added bottom padding
          child: Container(
            width: 500, // Set the desired width here
            padding: const EdgeInsets.all(12.0), // Reduced padding
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Edit Category',
                    style: GoogleFonts.vt323(
                      color: Colors.black, // Changed text color to black
                      fontSize: 60, // Increased font size
                    ),
                  ),
                  const SizedBox(height: 15), // Reduced spacing
                  SizedBox(
                    width: 300, // Fixed width for the Name field
                    child: TextFormField(
                      initialValue: _name,
                      decoration: InputDecoration(
                        labelText: 'Category Name',
                        labelStyle: GoogleFonts.vt323(
                          color: Colors.black,
                          fontSize: 20,
                        ),
                        filled: true,
                        fillColor: Colors.transparent, // Transparent box background
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(0.0), // Square corners
                          borderSide: const BorderSide(color: Colors.black, width: 2.0), // Black border
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(0.0), // Square corners
                          borderSide: const BorderSide(color: Colors.black, width: 2.0), // Black border
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(0.0), // Square corners
                          borderSide: const BorderSide(color: Colors.black, width: 2.0), // Black border
                        ),
                      ),
                      style: const TextStyle(color: Colors.black), // Text color inside the field
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a category name';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _name = value!;
                      },
                    ),
                  ),
                  const SizedBox(height: 15), // Reduced spacing
                  SizedBox(
                    width: 300, // Fixed width for the Description field
                    child: TextFormField(
                      initialValue: _description,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        labelStyle: GoogleFonts.vt323(
                          color: Colors.black,
                          fontSize: 20,
                        ),
                        filled: true,
                        fillColor: Colors.transparent, // Transparent box background
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(0.0), // Square corners
                          borderSide: const BorderSide(color: Colors.black, width: 2.0), // Black border
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(0.0), // Square corners
                          borderSide: const BorderSide(color: Colors.black, width: 2.0), // Black border
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(0.0), // Square corners
                          borderSide: const BorderSide(color: Colors.black, width: 2.0), // Black border
                        ),
                      ),
                      style: const TextStyle(color: Colors.black), // Text color inside the field
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _description = value!;
                      },
                    ),
                  ),
                  const SizedBox(height: 30), // Reduced spacing
                  ElevatedButton(
                    onPressed: _saveCategory,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF1B33A), // Color for the save button
                      shadowColor: Colors.transparent, // Remove button highlight
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(0.0), // Square corners
                        side: const BorderSide(color: Colors.black, width: 2.0), // Black border
                      ),
                    ),
                    child: Text('Save Category', style: GoogleFonts.vt323(color: Colors.white, fontSize: 20)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}