import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../services/banner_service.dart';

class EditBannerDialog extends StatefulWidget {
  final Map<String, dynamic> banner;

  const EditBannerDialog({super.key, required this.banner});

  @override
  EditBannerDialogState createState() => EditBannerDialogState();
}

class EditBannerDialogState extends State<EditBannerDialog> {
  late TextEditingController _imageUrlController;
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  final BannerService _bannerService = BannerService();

  @override
  void initState() {
    super.initState();
    _imageUrlController = TextEditingController(text: widget.banner['img']);
    _titleController = TextEditingController(text: widget.banner['title']);
    _descriptionController = TextEditingController(text: widget.banner['description']);
  }

  void _updateBanner() async {
    final int id = widget.banner['id'];
    final String imageUrl = _imageUrlController.text;
    final String title = _titleController.text;
    final String description = _descriptionController.text;

    if (imageUrl.isNotEmpty && title.isNotEmpty && description.isNotEmpty) {
      final Map<String, dynamic> updatedBanner = {
        'id': id,
        'img': imageUrl,
        'title': title,
        'description': description,
      };
      await _bannerService.updateBanner(id, updatedBanner);

      if (!mounted) return;

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit Banner', style: GoogleFonts.vt323(color: Colors.black, fontSize: 20)),
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
          onPressed: _updateBanner,
          child: Text('Save', style: GoogleFonts.vt323(color: Colors.black, fontSize: 20)),
        ),
      ],
    );
  }
}