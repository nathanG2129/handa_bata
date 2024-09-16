// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/stage_service.dart';
import 'edit_stage_page.dart';
import 'add_stage_page.dart';
import 'admin_widgets/hoverable_text.dart';
import 'admin_widgets/stage_deletion_dialog.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  // ignore: library_private_types_in_public_api
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

  void _showAddStageDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddStageDialog(language: _selectedLanguage, category: _selectedCategory);
      },
    ).then((_) {
      _fetchStages();
    });
  }

  void _navigateToEditStage(String stageName) async {
    print('Navigating to edit stage: $stageName');
    List<Map<String, dynamic>> questions = await _stageService.fetchQuestions(_selectedLanguage, _selectedCategory, stageName);
    Navigator.push(
      // ignore: use_build_context_synchronously
      context,
      MaterialPageRoute(builder: (context) => EditStagePage(language: _selectedLanguage, category: _selectedCategory, stageName: stageName, questions: questions)),
    ).then((_) {
      _fetchStages();
    });
  }

  void _deleteStage(String stageName) async {
    print('Deleting stage: $stageName');
    bool confirm = await StageDeletionDialog(stageName: stageName, context: context).show();

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
    return MaterialApp(
      theme: ThemeData(
        textTheme: GoogleFonts.vt323TextTheme().apply(bodyColor: Colors.white, displayColor: Colors.white),
      ),
      home: Scaffold(
        backgroundColor: const Color(0xFF381c64),
        body: Stack(
          children: [
            Positioned.fill(
              child: SvgPicture.asset(
                'assets/backgrounds/background.svg',
                fit: BoxFit.cover,
              ),
            ),
            Column(
              children: [
                NavBar(
                  onEnglishTap: _editEnglishStages,
                  onFilipinoTap: _editFilipinoStages,
                ),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20),
                          CategoryDropdown(
                            selectedCategory: _selectedCategory,
                            onCategoryChanged: _selectCategory,
                          ),
                          const SizedBox(height: 20),
                          AddStageButton(
                            selectedLanguage: _selectedLanguage,
                            onPressed: _showAddStageDialog,
                          ),
                          const SizedBox(height: 20),
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: StageDataTable(
                                stages: _stages,
                                onEditStage: _navigateToEditStage,
                                onDeleteStage: _deleteStage,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class NavBar extends StatelessWidget {
  final VoidCallback onEnglishTap;
  final VoidCallback onFilipinoTap;

  const NavBar({
    super.key,
    required this.onEnglishTap,
    required this.onFilipinoTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF381c64),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Admin Panel', style: GoogleFonts.vt323(color: Colors.white, fontSize: 35)),
          ),
          Align(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.only(top: 11.0), // Adjust this value to move the buttons down
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  HoverableText(text: 'English', onTap: onEnglishTap),
                  const SizedBox(width: 16),
                  HoverableText(text: 'Filipino', onTap: onFilipinoTap),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CategoryDropdown extends StatelessWidget {
  final String selectedCategory;
  final ValueChanged<String> onCategoryChanged;

  const CategoryDropdown({
    super.key,
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: selectedCategory,
      dropdownColor: const Color(0xFF381c64),
      onChanged: (String? newValue) {
        if (newValue != null) {
          onCategoryChanged(newValue);
        }
      },
      items: <String>['Storm', 'Quake', 'Volcanic', 'Drought', 'Tsunami', 'Flood']
          .map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value, style: GoogleFonts.vt323(color: Colors.white, fontSize: 20)),
        );
      }).toList(),
    );
  }
}

class AddStageButton extends StatelessWidget {
  final String selectedLanguage;
  final VoidCallback onPressed;

  const AddStageButton({
    super.key,
    required this.selectedLanguage,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF381c64),
        shadowColor: Colors.transparent, // Remove button highlight
      ),
      child: Text(
        selectedLanguage == 'en' ? 'Add English Stage' : 'Add Filipino Stage',
        style: GoogleFonts.vt323(color: Colors.white, fontSize: 20),
      ),
    );
  }
}

class StageDataTable extends StatelessWidget {
  final List<Map<String, dynamic>> stages;
  final ValueChanged<String> onEditStage;
  final ValueChanged<String> onDeleteStage;

  const StageDataTable({
    super.key,
    required this.stages,
    required this.onEditStage,
    required this.onDeleteStage,
  });

  @override
  Widget build(BuildContext context) {
    return DataTable(
      columns: [
        DataColumn(label: Text('Stage Name', style: GoogleFonts.vt323(color: Colors.white, fontSize: 20))),
        DataColumn(label: Text('Number of Questions', style: GoogleFonts.vt323(color: Colors.white, fontSize: 20))),
        DataColumn(label: Text('Actions', style: GoogleFonts.vt323(color: Colors.white, fontSize: 20))),
      ],
      rows: stages.map((stage) {
        String stageName = stage['stageName'] ?? '';
        int questionCount = stage['questions'] != null ? (stage['questions'] as List).length : 0;
        return DataRow(cells: [
          DataCell(Text(stageName, style: GoogleFonts.vt323(color: Colors.white, fontSize: 20))),
          DataCell(Text(questionCount.toString(), style: GoogleFonts.vt323(color: Colors.white, fontSize: 20))),
          DataCell(
            Row(
              children: [
                ElevatedButton(
                  onPressed: stageName.isNotEmpty ? () => onEditStage(stageName) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF381c64),
                    shadowColor: Colors.transparent, // Remove button highlight
                  ),
                  child: Text('Edit', style: GoogleFonts.vt323(color: Colors.white, fontSize: 20)),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: stageName.isNotEmpty ? () => onDeleteStage(stageName) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shadowColor: Colors.transparent, // Remove button highlight
                  ),
                  child: Text('Delete', style: GoogleFonts.vt323(color: Colors.white, fontSize: 20)),
                ),
              ],
            ),
          ),
        ]);
      }).toList(),
    );
  }
}