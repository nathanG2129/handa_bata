import 'package:flutter/material.dart';
import '../services/stage_service.dart';

class AddStagePage extends StatefulWidget {
  final String language;

  const AddStagePage({super.key, required this.language});

  @override
  _AddStagePageState createState() => _AddStagePageState();
}

class _AddStagePageState extends State<AddStagePage> {
  final _formKey = GlobalKey<FormState>();
  final StageService _stageService = StageService();
  String _stageName = '';
  List<Map<String, dynamic>> _questions = [];

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
      await _stageService.addStage(widget.language, _stageName, _questions);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Stage'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
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
                      trailing: IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          setState(() {
                            _questions.removeAt(index);
                          });
                        },
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