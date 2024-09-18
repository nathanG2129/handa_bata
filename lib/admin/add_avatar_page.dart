import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/avatar_service.dart';

class AddAvatarDialog extends StatefulWidget {
  const AddAvatarDialog({super.key});

  @override
  _AddAvatarDialogState createState() => _AddAvatarDialogState();
}

class _AddAvatarDialogState extends State<AddAvatarDialog> {
  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final AvatarService _avatarService = AvatarService();

  void _addAvatar() async {
    final String imageUrl = _imageUrlController.text;
    final String title = _titleController.text;

    if (imageUrl.isNotEmpty && title.isNotEmpty) {
      final Map<String, dynamic> avatar = {
        'img': imageUrl,
        'title': title,
      };
      await _avatarService.addAvatar(avatar);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add Avatar', style: GoogleFonts.vt323(color: Colors.black, fontSize: 20)),
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
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: GoogleFonts.vt323(color: Colors.black, fontSize: 20)),
        ),
        TextButton(
          onPressed: _addAvatar,
          child: Text('Add', style: GoogleFonts.vt323(color: Colors.black, fontSize: 20)),
        ),
      ],
    );
  }
}