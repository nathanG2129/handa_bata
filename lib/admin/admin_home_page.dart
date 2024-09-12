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
  Map<String, List<Map<String, dynamic>>> _categorizedStages = {};

  @override
  void initState() {
    super.initState();
    _fetchStages();
  }

  void _fetchStages() async {
    List<Map<String, dynamic>> stages = await _stageService.fetchStages(_selectedLanguage, _selectedCategory);
    print('Fetched stages: $stages');
    setState(() {
      _categorizedStages = {
        'Quake': [],
        'Storm': [],
        'Volcanic': [],
        'Drought': [],
        'Tsunami': [],
        'Flood': [],
      };
      for (var stage in stages) {
        int questionCount = (stage['questions'] as List<dynamic>?)?.length ?? 0;
        String category = stage['category'] ?? 'Uncategorized';
        if (_categorizedStages.containsKey(category)) {
          _categorizedStages[category]!.add({
            'stageName': stage['stageName'],
            'questionCount': questionCount,
          });
        } else {
          _categorizedStages['Uncategorized']!.add({
            'stageName': stage['stageName'],
            'questionCount': questionCount,
          });
        }
      }
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

  void _navigateToEditStage(String category, String stageName) async {
    List<Map<String, dynamic>> questions = await _stageService.fetchQuestions(_selectedLanguage, category, stageName);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditStagePage(language: _selectedLanguage, stageName: stageName, questions: questions, category: '',)),
    ).then((_) {
      _fetchStages();
    });
  }

  void _deleteStage(String category, String stageName) async {
    await _stageService.deleteStage(_selectedLanguage, category, stageName);
    _fetchStages();
<<<<<<< HEAD
  }

  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = category;
      _fetchStages();
    });
=======
>>>>>>> 2b82e4b069e647a37159e023a13e2488a8bf81b2
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
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // 2 columns
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.8, // Adjust the aspect ratio to make the items smaller
                ),
                itemCount: _categorizedStages.length,
                itemBuilder: (context, index) {
                  String category = _categorizedStages.keys.elementAt(index);
                  List<Map<String, dynamic>> stages = _categorizedStages[category]!;
                  return Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            category,
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: stages.length,
                            itemBuilder: (context, stageIndex) {
                              final stage = stages[stageIndex];
                              return ListTile(
                                title: Text(stage['stageName']),
                                subtitle: Text('Questions: ${stage['questionCount']}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.edit),
                                      onPressed: () => _navigateToEditStage(category, stage['stageName']),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete),
                                      onPressed: () => _deleteStage(category, stage['stageName']),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
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