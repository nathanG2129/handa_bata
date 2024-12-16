import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/services/resource_service.dart';

class EditResourceDialog extends StatefulWidget {
  final Map<String, dynamic> resource;

  const EditResourceDialog({
    super.key,
    required this.resource,
  });

  @override
  _EditResourceDialogState createState() => _EditResourceDialogState();
}

class _EditResourceDialogState extends State<EditResourceDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _srcController;
  late final TextEditingController _referenceController;
  late final TextEditingController _thumbnailPathController;
  late String _selectedType;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.resource['title']);
    _srcController = TextEditingController(text: widget.resource['src']);
    _referenceController = TextEditingController(text: widget.resource['reference']);
    _thumbnailPathController = TextEditingController(text: widget.resource['thumbnailPath'] ?? '');
    _selectedType = widget.resource['type'];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _srcController.dispose();
    _referenceController.dispose();
    _thumbnailPathController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final updatedResource = {
        ...widget.resource,
        'title': _titleController.text,
        'type': _selectedType,
        'src': _srcController.text,
        'reference': _referenceController.text,
        if (_selectedType == 'infographic') 'thumbnailPath': _thumbnailPathController.text,
      };

      await ResourceService().updateResource(updatedResource);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF381c64),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0),
        side: const BorderSide(color: Colors.black, width: 2),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Edit Resource',
                  style: GoogleFonts.vt323(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                
                // Type Selection
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  decoration: InputDecoration(
                    labelText: 'Type',
                    labelStyle: GoogleFonts.vt323(color: Colors.white),
                    border: const OutlineInputBorder(),
                    enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                  dropdownColor: const Color(0xFF381c64),
                  style: GoogleFonts.vt323(color: Colors.white),
                  items: [
                    DropdownMenuItem(
                      value: 'video',
                      child: Text('Video', style: GoogleFonts.vt323()),
                    ),
                    DropdownMenuItem(
                      value: 'infographic',
                      child: Text('Infographic', style: GoogleFonts.vt323()),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Title
                TextFormField(
                  controller: _titleController,
                  style: GoogleFonts.vt323(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Title',
                    labelStyle: GoogleFonts.vt323(color: Colors.white),
                    border: const OutlineInputBorder(),
                    enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Source
                TextFormField(
                  controller: _srcController,
                  style: GoogleFonts.vt323(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: _selectedType == 'video' ? 'YouTube Video ID' : 'Image Path',
                    labelStyle: GoogleFonts.vt323(color: Colors.white),
                    border: const OutlineInputBorder(),
                    enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a source';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Reference
                TextFormField(
                  controller: _referenceController,
                  style: GoogleFonts.vt323(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Reference Organization',
                    labelStyle: GoogleFonts.vt323(color: Colors.white),
                    border: const OutlineInputBorder(),
                    enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a reference';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Thumbnail Path (only for infographics)
                if (_selectedType == 'infographic')
                  Column(
                    children: [
                      TextFormField(
                        controller: _thumbnailPathController,
                        style: GoogleFonts.vt323(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Thumbnail Path',
                          labelStyle: GoogleFonts.vt323(color: Colors.white),
                          border: const OutlineInputBorder(),
                          enabledBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                          ),
                        ),
                        validator: (value) {
                          if (_selectedType == 'infographic' && (value == null || value.isEmpty)) {
                            return 'Please enter a thumbnail path';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),

                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      _error!,
                      style: GoogleFonts.vt323(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.vt323(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'Save',
                              style: GoogleFonts.vt323(color: Colors.white),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 