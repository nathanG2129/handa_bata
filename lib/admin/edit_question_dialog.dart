import 'package:flutter/material.dart';

class EditQuestionDialog extends StatefulWidget {
  final Map<String, dynamic> question;
  final Function(Map<String, dynamic>) onSave;

  const EditQuestionDialog({super.key, required this.question, required this.onSave});

  @override
  _EditQuestionDialogState createState() => _EditQuestionDialogState();
}

class _EditQuestionDialogState extends State<EditQuestionDialog> {
  late Map<String, dynamic> _question;
  late List<TextEditingController> _optionControllers;

  @override
  void initState() {
    super.initState();
    _question = Map<String, dynamic>.from(widget.question);
    _initializeQuestionFields();
    _optionControllers = List.generate(
      _question['options'].length,
      (index) => TextEditingController(text: _question['options'][index]),
    );
  }

  void _initializeQuestionFields() {
    if (_question['type'] == 'Fill in the Blanks' || _question['type'] == 'Multiple Choice' || _question['type'] == 'Matching Type') {
      _question['answer'] ??= 0;
      _question['options'] ??= <String>[];
    } else if (_question['type'] == 'Identification') {
      _question['answer'] ??= '';
      _question['answerLength'] ??= 0;
      _question['options'] ??= <String>[];
      _question['space'] ??= <String>[];
    }
  }

  void _addOption() {
    setState(() {
      _question['options'].add('');
      _optionControllers.add(TextEditingController());
    });
  }

  void _removeOption(int index) {
    setState(() {
      _question['options'].removeAt(index);
      _optionControllers.removeAt(index);
    });
  }

  void _save() {
    _question['options'] = _optionControllers.map((controller) => controller.text).toList();
    widget.onSave(_question);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit Question'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _question['type'],
              items: ['Identification', 'Multiple Choice', 'Matching Type', 'Fill in the Blanks']
                  .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _question['type'] = value!;
                  _initializeQuestionFields();
                });
              },
              decoration: InputDecoration(labelText: 'Question Type'),
            ),
            TextFormField(
              initialValue: _question['question'],
              decoration: InputDecoration(labelText: 'Question'),
              onChanged: (value) {
                _question['question'] = value;
              },
            ),
            if (_question['type'] == 'Identification') ...[
              TextFormField(
                initialValue: _question['answer'],
                decoration: InputDecoration(labelText: 'Answer'),
                onChanged: (value) {
                  _question['answer'] = value;
                },
              ),
              TextFormField(
                initialValue: _question['answerLength'].toString(),
                decoration: InputDecoration(labelText: 'Answer Length'),
                onChanged: (value) {
                  _question['answerLength'] = int.tryParse(value) ?? 0;
                },
              ),
              ..._optionControllers.map((controller) {
                int index = _optionControllers.indexOf(controller);
                return Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: controller,
                        decoration: InputDecoration(labelText: 'Option ${index + 1}'),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () => _removeOption(index),
                    ),
                  ],
                );
              }).toList(),
              ElevatedButton(
                onPressed: _addOption,
                child: Text('Add Option'),
              ),
              TextFormField(
                initialValue: (_question['space'] as List<dynamic>?)?.join(', ') ?? '',
                decoration: InputDecoration(labelText: 'Space (comma separated)'),
                onChanged: (value) {
                  _question['space'] = value.split(',').map((e) => e.trim()).toList();
                },
              ),
            ],
            if (_question['type'] == 'Multiple Choice' || _question['type'] == 'Fill in the Blanks' || _question['type'] == 'Matching Type') ...[
              TextFormField(
                initialValue: _question['answer'].toString(),
                decoration: InputDecoration(labelText: 'Answer (index)'),
                onChanged: (value) {
                  _question['answer'] = int.tryParse(value) ?? 0;
                },
              ),
              ..._optionControllers.map((controller) {
                int index = _optionControllers.indexOf(controller);
                return Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: controller,
                        decoration: InputDecoration(labelText: 'Option ${index + 1}'),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () => _removeOption(index),
                    ),
                  ],
                );
              }).toList(),
              ElevatedButton(
                onPressed: _addOption,
                child: Text('Add Option'),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: _save,
          child: Text('Save'),
        ),
      ],
    );
  }
}