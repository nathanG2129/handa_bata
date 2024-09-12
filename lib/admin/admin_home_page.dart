import 'package:flutter/material.dart';
import '/services/stage_service.dart';
import '/admin/add_stage_page.dart';
import '/admin/edit_stage_page.dart';

class AdminHomePage extends StatefulWidget {
  @override
  _AdminHomePageState createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  final StageService _stageService = StageService();
  String _selectedLanguage = 'en';
  List<Map<String, dynamic>> _stages = [];

  @override
  void initState() {
    super.initState();
    _fetchStages();
  }

  void _fetchStages() async {
    List<Map<String, dynamic>> stages = await _stageService.fetchStages(_selectedLanguage);
    setState(() {
      _stages = stages.map((stage) {
        int questionCount = (stage['questions'] as List<dynamic>?)?.length ?? 0;
        return {
          'stageName': stage['stageName'],
          'questionCount': questionCount,
        };
      }).toList();
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
      _fetchStages();
    });
  }

  void _navigateToEditStage(String stageName) async {
    List<Map<String, dynamic>> questions = await _stageService.fetchQuestions(_selectedLanguage, stageName);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditStagePage(language: _selectedLanguage, stageName: stageName, questions: questions)),
    ).then((_) {
      _fetchStages();
    });
  }

  void _deleteStage(String stageName) async {
    await _stageService.deleteStage(_selectedLanguage, stageName);
    _fetchStages();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Home Page'),
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _editEnglishStages,
                child: Text('Edit English Stages'),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: _editFilipinoStages,
                child: Text('Edit Filipino Stages'),
              ),
            ],
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _stages.length,
              itemBuilder: (context, index) {
                final stage = _stages[index];
                return Center(
                  child: Container(
                    width: 300, // Adjust the width as needed
                    child: Card(
                      child: ListTile(
                        title: Text(stage['stageName']),
                        subtitle: Text('Questions: ${stage['questionCount']}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: () => _navigateToEditStage(stage['stageName']),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () => _deleteStage(stage['stageName']),
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
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddStage,
        child: Icon(Icons.add),
      ),
    );
  }
}