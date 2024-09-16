import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StageDeletionDialog extends StatelessWidget {
  final String stageName;
  final BuildContext context;

  const StageDeletionDialog({required this.stageName, required this.context, Key? key}) : super(key: key);

  Future<bool> show() async {
    return await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm Deletion', style: GoogleFonts.vt323(color: Colors.white)),
          content: Text('Are you sure you want to delete the stage "$stageName"?', style: GoogleFonts.vt323(color: Colors.white)),
          backgroundColor: Color(0xFF381c64),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: GoogleFonts.vt323(color: Colors.white)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Delete', style: GoogleFonts.vt323(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(); // This widget is not meant to be used directly in the widget tree
  }
}