import 'package:flutter/material.dart';
import '../services/stage_service.dart';
import 'edit_question_dialog.dart';
import 'question_list_item.dart';

class EditStagePage extends StatefulWidget {
  final String language;
  final String category;
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
  late TextEditingController _stageNameController;
  late String _stageName;
  late List<Map<String, dynamic>> _questions;
  late String _selectedCategory;

  @override
  void initState() {
    super.initState();
    _stageNameController = TextEditingController(text: widget.stageName);
    _questions = List<Map<String, dynamic>>.from(widget.questions);
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Center(
                child: Container(
                  width: 300,
                  child: TextFormField(
                    controller: _stageNameController,
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
                ),
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
                    return Center(
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.6, // 60% of screen width
                        child: Card(
                          margin: EdgeInsets.symmetric(vertical: 8.0),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Question ${index + 1}: ${_questions[index]['question']}',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 8.0),
                                if (_questions[index]['options'] != null && _questions[index]['options'].isNotEmpty)
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Options:'),
                                      ..._questions[index]['options'].map<Widget>((option) {
                                        return Text('- $option');
                                      }).toList(),
                                    ],
                                  ),
                                if (_questions[index]['answer'] != null && _questions[index]['answer'].isNotEmpty)
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Answer:'),
                                      Text('- ${_questions[index]['answer']}'),
                                    ],
                                  ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
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
                              ],
                            ),
                          ),
                        ),
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