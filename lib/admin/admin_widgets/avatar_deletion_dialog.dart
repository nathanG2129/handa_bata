import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AvatarDeletionDialog {
  final String avatarId;
  final BuildContext context;

  AvatarDeletionDialog({required this.avatarId, required this.context});

  Future<bool> show() async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF381c64),
          title: Text('Delete Avatar', style: GoogleFonts.vt323(color: Colors.white, fontSize: 25)),
          content: Text(
            'Are you sure you want to delete the avatar with ID: $avatarId?',
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