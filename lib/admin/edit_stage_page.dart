import 'package:flutter/material.dart';
import '../services/stage_service.dart';

class EditStagePage extends StatefulWidget {
  final String language;
  final String stageName;
  final List<Map<String, dynamic>> questions;
  final String category;

  const EditStagePage({
    super.key,
    required this.language,
    required this.stageName,
    required this.questions,
    required this.category,
  });

  @override
  _EditStagePageState createState() => _EditStagePageState();
}

class _EditStagePageState extends State<EditStagePage> {
  final _formKey = GlobalKey<FormState>();
  final StageService _stageService = StageService();
  late String _stageName;
  late List<Map<String, dynamic>> _questions;
  late String _selectedCategory;

  @override
  void initState() {
    super.initState();
    _stageName = widget.stageName;
    _questions = widget.questions.map((question) {
      return {
        'type': question['type'] ?? 'Identification',
        'question': question['question'] ?? '',
        'answer': question['answer'] ?? '',
        'answerLength': question['answerLength'] ?? 0,
        'options': question['options'] ?? [],
        'space': question['space'] ?? [],
      };
    }).toList();
    _selectedCategory = widget.category;
  }

  void _addQuestion() {
    setState(() {
      _questions.add({
        'type': 'Identification',
        'question': '',
        'answer': '',
        'answerLength': 0,
        'options': [],
        'space': [],
      });
    });
  }

  void _saveStage() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      await _stageService.updateStage(widget.language, _selectedCategory, _stageName, _questions);
      Navigator.pop(context);
    }
  }

  void _editQuestion(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return EditQuestionDialog(
          question: _questions[index],
          onSave: (updatedQuestion) {
            setState(() {
              _questions[index] = updatedQuestion;
            });
          },
        );
      },
    );
  }

  void _removeQuestion(int index) {
    setState(() {
      _questions.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Stage'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                initialValue: _stageName,
                decoration: InputDecoration(labelText: 'Stage Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a stage name';
                  }
                  return null;
                },
                onSaved: (value) {
                  _stageName = value!;
                },
              ),
              SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: ['Quake', 'Storm', 'Volcanic', 'Drought', 'Tsunami', 'Flood']
                    .map((category) => DropdownMenuItem(value: category, child: Text(category)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
                decoration: InputDecoration(labelText: 'Category'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _addQuestion,
                child: Text('Add Question'),
              ),
              SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: _questions.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text('Question ${index + 1}'),
                      subtitle: Text(_questions[index]['type']),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () => _editQuestion(index),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () => _removeQuestion(index),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveStage,
                child: Text('Save Stage'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EditQuestionDialog extends StatefulWidget {
  final Map<String, dynamic> question;
  final Function(Map<String, dynamic>) onSave;

  const EditQuestionDialog({super.key, required this.question, required this.onSave});

  @override
  _EditQuestionDialogState createState() => _EditQuestionDialogState();
}

class _EditQuestionDialogState extends State<EditQuestionDialog> {
  late Map<String, dynamic> _question;

  @override
  void initState() {
    super.initState();
    _question = Map<String, dynamic>.from(widget.question);
    _initializeQuestionFields();
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

  void _save() {
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
              TextFormField(
                initialValue: (_question['options'] as List<dynamic>?)?.join(', ') ?? '',
                decoration: InputDecoration(labelText: 'Options (comma separated)'),
                onChanged: (value) {
                  _question['options'] = value.split(',').map((e) => e.trim()).toList();
                },
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
              TextFormField(
                initialValue: (_question['options'] as List<dynamic>?)?.join(', ') ?? '',
                decoration: InputDecoration(labelText: 'Options (comma separated)'),
                onChanged: (value) {
                  _question['options'] = value.split(',').map((e) => e.trim()).toList();
                },
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