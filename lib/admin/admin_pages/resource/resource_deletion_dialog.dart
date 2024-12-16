import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ResourceDeletionDialog {
  final int resourceId;
  final BuildContext context;

  ResourceDeletionDialog({
    required this.resourceId,
    required this.context,
  });

  Future<bool> show() async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF381c64),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0),
            side: const BorderSide(color: Colors.black, width: 2),
          ),
          title: Text(
            'Delete Resource',
            style: GoogleFonts.vt323(
              color: Colors.white,
              fontSize: 24,
            ),
          ),
          content: Text(
            'Are you sure you want to delete this resource? This action cannot be undone.',
            style: GoogleFonts.vt323(
              color: Colors.white,
              fontSize: 18,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: GoogleFonts.vt323(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: Text(
                'Delete',
                style: GoogleFonts.vt323(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        );
      },
    ) ?? false;
  }
} 