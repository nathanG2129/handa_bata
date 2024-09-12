import 'package:flutter/material.dart';
import '../services/stage_service.dart';
import 'edit_stage_page.dart';
import 'add_stage_page.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  _AdminHomePageState createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  final StageService _stageService = StageService();
  List<Map<String, dynamic>> _stages = [];
  String _selectedLanguage = 'en';
  String _selectedCategory = 'Storm'; // Default category

  @override
  void initState() {
    super.initState();
    _fetchStages();
  }

  void _fetchStages() async {
    List<Map<String, dynamic>> stages = await _stageService.fetchStages(_selectedLanguage, _selectedCategory);
    print('Fetched stages: $stages');
    setState(() {
      _stages = stages.map((stage) {
        // Ensure stageName is not null
        String stageName = stage['stageName'] ?? 'Unnamed Stage';
        return {
          ...stage,
          'stageName': stageName,
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
      MaterialPageRoute(builder: (context) => AddStagePage(language: _selectedLanguage, category: _selectedCategory)),
    ).then((_) {
      _fetchStages();
    });
  }

  void _navigateToEditStage(String stageName) async {
    print('Navigating to edit stage: $stageName');
    List<Map<String, dynamic>> questions = await _stageService.fetchQuestions(_selectedLanguage, _selectedCategory, stageName);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditStagePage(language: _selectedLanguage, category: _selectedCategory, stageName: stageName, questions: questions)),
    ).then((_) {
      _fetchStages();
    });
  }

  void _deleteStage(String stageName) async {
    print('Deleting stage: $stageName');
    bool confirm = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete the stage "$stageName"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm) {
      await _stageService.deleteStage(_selectedLanguage, _selectedCategory, stageName);
      _fetchStages();
    }
  }

  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = category;
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
              DropdownButton<String>(
                value: _selectedCategory,
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    _selectCategory(newValue);
                  }
                },
                items: <String>['Storm', 'Quake', 'Volcanic', 'Drought', 'Tsunami', 'Flood']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
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
                      DataColumn(label: Text('Number of Questions')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: _stages.map((stage) {
                      String stageName = stage['stageName'] ?? '';
                      int questionCount = stage['questions'] != null ? (stage['questions'] as List).length : 0;
                      return DataRow(cells: [
                        DataCell(Text(stageName)),
                        DataCell(Text(questionCount.toString())),
                        DataCell(
                          Row(
                            children: [
                              ElevatedButton(
                                onPressed: stageName.isNotEmpty ? () => _navigateToEditStage(stageName) : null,
                                child: Text('Edit'),
                              ),
                              SizedBox(width: 10),
                              ElevatedButton(
                                onPressed: stageName.isNotEmpty ? () => _deleteStage(stageName) : null,
                                child: Text('Delete'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                              ),
                            ],
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