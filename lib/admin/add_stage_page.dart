import 'package:flutter/material.dart';
import '../services/stage_service.dart';

class AddStagePage extends StatefulWidget {
  final String language;
  final String category;

<<<<<<< HEAD
  const AddStagePage({super.key, required this.language, required this.category});
=======
  AddStagePage({required this.language});
>>>>>>> 2b82e4b069e647a37159e023a13e2488a8bf81b2

  @override
  _AddStagePageState createState() => _AddStagePageState();
}

class _AddStagePageState extends State<AddStagePage> {
  final StageService _stageService = StageService();
  final TextEditingController _stageNameController = TextEditingController();
  final List<Map<String, dynamic>> _questions = [];
  String _selectedCategory = 'Quake';

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
      await _stageService.addStage(widget.language, _selectedCategory, stageName, _questions);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Stage added successfully.')));
      Navigator.pop(context); // Go back to the previous page
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please enter a stage name and add at least one question.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Stage'),
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