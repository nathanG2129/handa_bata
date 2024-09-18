import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BannerDeletionDialog {
  final int bannerId;
  final BuildContext context;

  BannerDeletionDialog({required this.bannerId, required this.context});

  Future<bool> show() async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF381c64),
          title: Text('Delete Banner', style: GoogleFonts.vt323(color: Colors.white, fontSize: 25)),
          content: Text(
            'Are you sure you want to delete the banner with ID: $bannerId?',
            style: GoogleFonts.vt323(color: Colors.white, fontSize: 20),
          ),
          actions: [
            TextButton(
              child: Text('Cancel', style: GoogleFonts.vt323(color: Colors.white, fontSize: 20)),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: Text('Delete', style: GoogleFonts.vt323(color: Colors.red, fontSize: 20)),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    ) ?? false;
  }
}