import 'package:flutter/material.dart';
import '../services/stage_service.dart';
import 'package:google_fonts/google_fonts.dart';

class AddStageDialog extends StatefulWidget {
  final String language;
  final String category;

  const AddStageDialog({super.key, required this.language, required this.category});

  @override
  _AddStageDialogState createState() => _AddStageDialogState();
}

class _AddStageDialogState extends State<AddStageDialog> {
  final _formKey = GlobalKey<FormState>();
  final StageService _stageService = StageService();
  String _stageName = '';

  void _saveStage() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      print('Saving stage: $_stageName');
      await _stageService.addStage(widget.language, widget.category, _stageName, {
        'stageName': _stageName,
      });
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
                    'Add Stage',
                    style: GoogleFonts.vt323(
                      color: Colors.white, // Changed text color to white
                      fontSize: 60, // Increased font size
                      shadows: [
                        const Shadow(
                          offset: Offset(-2, -2), // Top-left shadow
                          color: Colors.black,
                        ),
                        const Shadow(
                          offset: Offset(2, -2), // Top-right shadow
                          color: Colors.black,
                        ),
                        const Shadow(
                          offset: Offset(2, 2), // Bottom-right shadow
                          color: Colors.black,
                        ),
                        const Shadow(
                          offset: Offset(-2, 2), // Bottom-left shadow
                          color: Colors.black,
                        ),
                        const Shadow(
                          offset: Offset(0, 5), // Offset for the shadow in y-direction
                          blurRadius: 0.0, // No blur
                          color: Colors.black, // Black color
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15), // Reduced spacing
                  SizedBox(
                    width: 300, // Fixed width for the Stage Name field
                    child: TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Stage Name',
                        labelStyle: GoogleFonts.vt323( // Changed font family to VT323
                          color: Colors.black,
                          fontSize: 20 // Changed label color to black
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
                          return 'Please enter a stage name';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _stageName = value!;
                      },
                    ),
                  ),
                  const SizedBox(height: 30), // Reduced spacing
                  ElevatedButton(
                    onPressed: _saveStage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF1B33A), // Color for the save button
                      shadowColor: Colors.transparent, // Remove button highlight
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(0.0), // Square corners
                        side: const BorderSide(color: Colors.black, width: 2.0), // Black border
                      ),
                    ),
                    child: Text('Save Stage', style: GoogleFonts.vt323(color: Colors.white, fontSize: 20)),
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