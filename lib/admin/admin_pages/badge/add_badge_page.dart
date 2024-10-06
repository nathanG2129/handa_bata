import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../services/badge_service.dart';

class AddBadgeDialog extends StatefulWidget {
  const AddBadgeDialog({super.key});

  @override
  AddBadgeDialogState createState() => AddBadgeDialogState();
}

class AddBadgeDialogState extends State<AddBadgeDialog> {
  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final BadgeService _badgeService = BadgeService();

  void _addBadge() async {
    final String imageUrl = _imageUrlController.text;
    final String title = _titleController.text;
    final String description = _descriptionController.text;

    if (imageUrl.isNotEmpty && title.isNotEmpty && description.isNotEmpty) {
      final Map<String, dynamic> badge = {
        'img': imageUrl,
        'title': title,
        'description': description,
      };
      await _badgeService.addBadge(badge);

      if (!mounted) return;

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add Badge', style: GoogleFonts.vt323(color: Colors.black, fontSize: 20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _imageUrlController,
            decoration: InputDecoration(
              labelText: 'Image URL',
              labelStyle: GoogleFonts.vt323(color: Colors.black, fontSize: 20),
            ),
          ),
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Title',
              labelStyle: GoogleFonts.vt323(color: Colors.black, fontSize: 20),
            ),
          ),
          TextField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: 'Description',
              labelStyle: GoogleFonts.vt323(color: Colors.black, fontSize: 20),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: GoogleFonts.vt323(color: Colors.black, fontSize: 20)),
        ),
        TextButton(
          onPressed: _addBadge,
          child: Text('Add', style: GoogleFonts.vt323(color: Colors.black, fontSize: 20)),
        ),
      ],
    );
  }
}