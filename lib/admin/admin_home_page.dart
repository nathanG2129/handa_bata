import 'package:flutter/material.dart';
import '../services/stage_service.dart';
import 'add_stage_page.dart';
import 'edit_stage_page.dart';

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

  void _navigateToEditStage(String stageName, List<Map<String, dynamic>> questions) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditStagePage(language: _selectedLanguage, stageName: stageName, questions: questions)),
    ).then((_) {
      // Refresh the stages list after returning from the EditStagePage
      _fetchStages();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Panel'),
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
                    child: Text('English'),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _editFilipinoStages,
                    child: Text('Filipino'),
                  ),
                ],
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _navigateToAddStage,
                child: Text('Add Stage'),
              ),
              SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: [
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
                            child: Text('Edit'),
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