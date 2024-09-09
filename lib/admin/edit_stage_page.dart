import 'package:flutter/material.dart';
import '../services/stage_service.dart';

class EditStagePage extends StatefulWidget {
  final String language;
  final String stageName;
  final List<Map<String, dynamic>> questions;

  EditStagePage({required this.language, required this.stageName, required this.questions});

  @override
  _EditStagePageState createState() => _EditStagePageState();
}

class _EditStagePageState extends State<EditStagePage> {
  final StageService _stageService = StageService();
  late TextEditingController _stageNameController;
  late List<Map<String, dynamic>> _questions;

  @override
  void initState() {
    super.initState();
    _stageNameController = TextEditingController(text: widget.stageName);
    _questions = List<Map<String, dynamic>>.from(widget.questions);
  }

  void _addQuestion() {
    setState(() {
      _questions.add({
        'question': '',
        'answer': '',
        'answerLength': 0,
        'options': [],
        'space': '',
        'type': '',
      });
    });
  }

  void _saveStage() async {
    final stageName = _stageNameController.text;
    if (stageName.isNotEmpty && _questions.isNotEmpty) {
      await _stageService.addStage(widget.language, stageName, _questions);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Stage updated successfully.')));
      Navigator.pop(context); // Go back to the previous page
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please enter a stage name and add at least one question.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Stage'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _stageNameController,
                decoration: InputDecoration(labelText: 'Stage Name'),
              ),
              SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: _questions.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text('Question ${index + 1}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            onChanged: (value) => _questions[index]['question'] = value,
                            decoration: InputDecoration(labelText: 'Question'),
                            controller: TextEditingController(text: _questions[index]['question']),
                          ),
                          TextField(
                            onChanged: (value) => _questions[index]['answer'] = value,
                            decoration: InputDecoration(labelText: 'Answer'),
                            controller: TextEditingController(text: _questions[index]['answer']),
                          ),
                          TextField(
                            onChanged: (value) => _questions[index]['answerLength'] = int.tryParse(value) ?? 0,
                            decoration: InputDecoration(labelText: 'Answer Length'),
                            controller: TextEditingController(text: _questions[index]['answerLength'].toString()),
                          ),
                          TextField(
                            onChanged: (value) => _questions[index]['options'] = value.split(','),
                            decoration: InputDecoration(labelText: 'Options (comma separated)'),
                            controller: TextEditingController(text: _questions[index]['options'].join(',')),
                          ),
                          TextField(
                            onChanged: (value) => _questions[index]['space'] = value,
                            decoration: InputDecoration(labelText: 'Space'),
                            controller: TextEditingController(text: _questions[index]['space']),
                          ),
                          TextField(
                            onChanged: (value) => _questions[index]['type'] = value,
                            decoration: InputDecoration(labelText: 'Type'),
                            controller: TextEditingController(text: _questions[index]['type']),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              ElevatedButton(
                onPressed: _addQuestion,
                child: Text('Add Question'),
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