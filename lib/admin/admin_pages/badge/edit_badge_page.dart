import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../services/badge_service.dart';

class EditBadgeDialog extends StatefulWidget {
  final Map<String, dynamic> badge;

  const EditBadgeDialog({super.key, required this.badge});

  @override
  EditBadgeDialogState createState() => EditBadgeDialogState();
}

class EditBadgeDialogState extends State<EditBadgeDialog> {
  late TextEditingController _imageUrlController;
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  final BadgeService _badgeService = BadgeService();

  @override
  void initState() {
    super.initState();
    _imageUrlController = TextEditingController(text: widget.badge['img']);
    _titleController = TextEditingController(text: widget.badge['title']);
    _descriptionController = TextEditingController(text: widget.badge['description']);
  }

  void _updateBadge() async {
    final int id = widget.badge['id'];
    final String imageUrl = _imageUrlController.text;
    final String title = _titleController.text;
    final String description = _descriptionController.text;

    if (imageUrl.isNotEmpty && title.isNotEmpty && description.isNotEmpty) {
      final Map<String, dynamic> updatedBadge = {
        'id': id,
        'img': imageUrl,
        'title': title,
        'description': description,
      };
      await _badgeService.updateBadge(id, updatedBadge);

      if (!mounted) return;

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit Badge', style: GoogleFonts.vt323(color: Colors.black, fontSize: 20)),
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
          onPressed: _updateBadge,
          child: Text('Save', style: GoogleFonts.vt323(color: Colors.black, fontSize: 20)),
        ),
      ],
    );
  }
}