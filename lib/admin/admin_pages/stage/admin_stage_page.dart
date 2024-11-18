// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/services/stage_service.dart';
import 'edit_stage_page.dart';
import 'add_stage_page.dart';
import 'package:handabatamae/admin/admin_widgets/hoverable_text.dart';
import 'package:handabatamae/admin/admin_widgets/stage_deletion_dialog.dart';
import 'edit_category_dialog.dart';
import 'package:handabatamae/admin/admin_widgets/add_stage_button.dart';
import 'package:handabatamae/admin/admin_widgets/category_dropdown.dart';
import 'package:handabatamae/admin/admin_widgets/stage_data_table.dart';

class AdminStagePage extends StatefulWidget {
  const AdminStagePage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _AdminStagePageState createState() => _AdminStagePageState();
}

class _AdminStagePageState extends State<AdminStagePage> {
  final StageService _stageService = StageService();
  List<Map<String, dynamic>> _stages = [];
  List<Map<String, dynamic>> _categories = [];
  String _selectedLanguage = 'en';
  String _selectedCategory = 'Storm';

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _fetchStages();
  }

  Future<void> _fetchCategories() async {
    List<Map<String, dynamic>> categories = await _stageService.fetchCategories(_selectedLanguage);
    setState(() {
      _categories = categories.map((category) {
        return {
          'id': category['id'],
          'name': category['name'] ?? 'Unnamed Category',
          'description': category['description'] ?? 'No description available',
        };
      }).toList();
    });
  }

  Future<void> _fetchStages() async {
    List<Map<String, dynamic>> stages = await _stageService.fetchStages(_selectedLanguage, _selectedCategory);
    print('Fetched stages: $stages');
    setState(() {
      _stages = stages.map((stage) {
        // Ensure stageName is not null
        String stageName = stage['stageName'] ?? 'Unnamed Stage';
        return {
          ...stage,
          'stageName': stageName,
          'stageDescription': stage['stageDescription'] ?? '', // Ensure stageDescription is included
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

  void _showEditCategoryDialog() async {
    try {
      final selectedCategory = _categories.firstWhere((category) => category['id'] == _selectedCategory, orElse: () => {});
  
      // Check if the required fields are present
      bool needsUpdate = false;
      if (selectedCategory['name'] == null) {
        selectedCategory['name'] = 'Unnamed Category';
        needsUpdate = true;
      }
      if (selectedCategory['description'] == null) {
        selectedCategory['description'] = 'No description available';
        needsUpdate = true;
      }
      if (selectedCategory['color'] == null) {
        selectedCategory['color'] = 'defaultColor';
        needsUpdate = true;
      }
      if (selectedCategory['position'] == null) {
        selectedCategory['position'] = 0;
        needsUpdate = true;
      }
  
      // Update the category if necessary
      if (needsUpdate) {
        await _stageService.updateCategory(_selectedLanguage, _selectedCategory, {
          'name': selectedCategory['name'],
          'description': selectedCategory['description'],
          'color': selectedCategory['color'],
          'position': selectedCategory['position'],
        });
        // Refresh categories after update
        await _fetchCategories();
      }
  
      // Show the edit dialog
      if (!mounted) return;
  
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return EditCategoryDialog(
            language: _selectedLanguage,
            categoryId: _selectedCategory,
            initialName: selectedCategory['name'],
            initialDescription: selectedCategory['description'],
            initialColor: selectedCategory['color'], // Pass initial color
            initialPosition: selectedCategory['position'], // Pass initial position
          );
        },
      ).then((_) {
        _fetchCategories();
      });
    } catch (e) {
      print('Error: $e');
      // Handle the error, e.g., show a message to the user
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selected category not found.')),
        );
      });
    }
  }

  void _navigateToEditStage(String stageName) async {
    print('Navigating to edit stage: $stageName');
    List<Map<String, dynamic>> questions = await _stageService.fetchQuestions(
      _selectedLanguage, 
      _selectedCategory, 
      stageName
    );
    Map<String, dynamic> stageData = await _stageService.fetchStageDocument(
      _selectedLanguage, 
      _selectedCategory, 
      stageName
    );
    
    if (!mounted) return;
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditStagePage(
          language: _selectedLanguage,
          category: _selectedCategory,
          stageName: stageName,
          questions: questions,
          stageData: stageData
        ),
      ),
    );

    // If the stage was updated successfully, refresh the stage list
    if (result == true) {
      await _fetchStages(); // Refresh the stage list
    }
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

  void _navigateBack(BuildContext context) {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        textTheme: GoogleFonts.vt323TextTheme().apply(bodyColor: Colors.white, displayColor: Colors.white),
      ),
      home: Scaffold(
        backgroundColor: const Color(0xFF381c64),
        appBar: AppBar(
          title: Text('Admin Panel', style: GoogleFonts.vt323(color: Colors.white, fontSize: 30)),
          backgroundColor: const Color(0xFF381c64),
          iconTheme: const IconThemeData(color: Colors.white), // Set the back button color to white
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _navigateBack(context),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Row(
                children: [
                  HoverableText(text: 'English', onTap: _editEnglishStages),
                  const SizedBox(width: 16),
                  HoverableText(text: 'Filipino', onTap: _editFilipinoStages),
                ],
              ),
            ),
          ],
        ),
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
                          ElevatedButton(
                            onPressed: _showEditCategoryDialog,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF381c64),
                              shadowColor: Colors.transparent, // Remove button highlight
                            ),
                            child: Text(
                              'Edit Stage Category',
                              style: GoogleFonts.vt323(color: Colors.white, fontSize: 20),
                            ),
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