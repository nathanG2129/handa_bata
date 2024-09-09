import 'package:flutter/material.dart';
import '../services/stage_service.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  _AdminHomePageState createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  final StageService _stageService = StageService();
  List<Map<String, dynamic>> _stages = [];
  String _selectedLanguage = 'en';

  @override
  void initState() {
    super.initState();
    _fetchStages();
  }

  void _fetchStages() async {
    List<Map<String, dynamic>> stages = await _stageService.fetchStages(_selectedLanguage);
    setState(() {
      _stages = stages;
    });
  }

  void _editEnglishStages() {
    setState(() {
      _selectedLanguage = 'en';
      _fetchStages();
    });
  }

  void _editFilipinoStages() {
    setState(() {
      _selectedLanguage = 'fil';
      _fetchStages();
    });
  }

  void _navigateToAddStage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddStagePage(language: _selectedLanguage)),
    ).then((_) {
      // Refresh the stages list after returning from the AddStagePage
      _fetchStages();
    });
  }

  void _navigateToEditStage(String stageName, List<dynamic> questions) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditStagePage(language: _selectedLanguage, stageName: stageName, questions: List<Map<String, dynamic>>.from(questions))),
    ).then((_) {
      // Refresh the stages list after returning from the EditStagePage
      _fetchStages();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: _editEnglishStages,
                    child: const Text('English'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _editFilipinoStages,
                    child: const Text('Filipino'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _navigateToAddStage,
                child: const Text('Add Stage'),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Stage Name')),
                      DataColumn(label: Text('Questions')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: _stages.map((stage) {
                      return DataRow(cells: [
                        DataCell(Text(stage['stageName'] ?? '')),
                        DataCell(Text(stage['questions'] != null ? stage['questions'].toString() : '')),
                        DataCell(
                          ElevatedButton(
                            onPressed: () => _navigateToEditStage(stage['stageName'], stage['questions']),
                            child: const Text('Edit'),
                          ),
                        ),
                      ]);
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AddStagePage extends StatefulWidget {
  final String language;

  const AddStagePage({super.key, required this.language});

  @override
  _AddStagePageState createState() => _AddStagePageState();
}

class _AddStagePageState extends State<AddStagePage> {
  final StageService _stageService = StageService();
  final TextEditingController _stageNameController = TextEditingController();
  final List<Map<String, dynamic>> _questions = [];

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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stage added successfully.')));
      Navigator.pop(context); // Go back to the previous page
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a stage name and add at least one question.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Stage'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _stageNameController,
                decoration: const InputDecoration(labelText: 'Stage Name'),
              ),
              const SizedBox(height: 20),
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
                            decoration: const InputDecoration(labelText: 'Question'),
                            controller: TextEditingController(text: _questions[index]['question']),
                          ),
                          TextField(
                            onChanged: (value) => _questions[index]['answer'] = value,
                            decoration: const InputDecoration(labelText: 'Answer'),
                            controller: TextEditingController(text: _questions[index]['answer']),
                          ),
                          TextField(
                            onChanged: (value) => _questions[index]['answerLength'] = int.tryParse(value) ?? 0,
                            decoration: const InputDecoration(labelText: 'Answer Length'),
                            controller: TextEditingController(text: _questions[index]['answerLength'].toString()),
                          ),
                          TextField(
                            onChanged: (value) => _questions[index]['options'] = value.split(','),
                            decoration: const InputDecoration(labelText: 'Options (comma separated)'),
                            controller: TextEditingController(text: _questions[index]['options'].join(',')),
                          ),
                          TextField(
                            onChanged: (value) => _questions[index]['space'] = value,
                            decoration: const InputDecoration(labelText: 'Space'),
                            controller: TextEditingController(text: _questions[index]['space']),
                          ),
                          TextField(
                            onChanged: (value) => _questions[index]['type'] = value,
                            decoration: const InputDecoration(labelText: 'Type'),
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
                child: const Text('Add Question'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveStage,
                child: const Text('Save Stage'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EditStagePage extends StatefulWidget {
  final String language;
  final String stageName;
  final List<Map<String, dynamic>> questions;

  const EditStagePage({super.key, required this.language, required this.stageName, required this.questions});

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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stage updated successfully.')));
      Navigator.pop(context); // Go back to the previous page
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a stage name and add at least one question.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Stage'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _stageNameController,
                decoration: const InputDecoration(labelText: 'Stage Name'),
              ),
              const SizedBox(height: 20),
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
                            decoration: const InputDecoration(labelText: 'Question'),
                            controller: TextEditingController(text: _questions[index]['question']),
                          ),
                          TextField(
                            onChanged: (value) => _questions[index]['answer'] = value,
                            decoration: const InputDecoration(labelText: 'Answer'),
                            controller: TextEditingController(text: _questions[index]['answer']),
                          ),
                          TextField(
                            onChanged: (value) => _questions[index]['answerLength'] = int.tryParse(value) ?? 0,
                            decoration: const InputDecoration(labelText: 'Answer Length'),
                            controller: TextEditingController(text: _questions[index]['answerLength'].toString()),
                          ),
                          TextField(
                            onChanged: (value) => _questions[index]['options'] = value.split(','),
                            decoration: const InputDecoration(labelText: 'Options (comma separated)'),
                            controller: TextEditingController(text: _questions[index]['options'].join(',')),
                          ),
                          TextField(
                            onChanged: (value) => _questions[index]['space'] = value,
                            decoration: const InputDecoration(labelText: 'Space'),
                            controller: TextEditingController(text: _questions[index]['space']),
                          ),
                          TextField(
                            onChanged: (value) => _questions[index]['type'] = value,
                            decoration: const InputDecoration(labelText: 'Type'),
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
                child: const Text('Add Question'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveStage,
                child: const Text('Save Stage'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}