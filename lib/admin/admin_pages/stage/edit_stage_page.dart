import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/services/stage_service.dart';
import 'package:handabatamae/admin/admin_widgets/edit_question_dialog.dart';
import 'package:handabatamae/admin/admin_widgets/question_card.dart'; // Import the new file
import 'package:handabatamae/admin/admin_widgets/question_buttons.dart'; // Import the new file

class EditStagePage extends StatefulWidget {
  final String language;
  final String category;
  final String stageName;
  final List<Map<String, dynamic>> questions;
  final Map<String, dynamic> stageData;

  const EditStagePage({super.key, required this.language, required this.category, required this.stageName, required this.questions, required this.stageData});

  @override
  EditStagePageState createState() => EditStagePageState();
}

class EditStagePageState extends State<EditStagePage> {
  final _formKey = GlobalKey<FormState>();
  final StageService _stageService = StageService();
  late TextEditingController _stageNameController;
  late List<Map<String, dynamic>> _questions;
  late TextEditingController _stageDescriptionController;

    @override
  void initState() {
    super.initState();
    _stageNameController = TextEditingController(text: widget.stageName);
    _stageDescriptionController = TextEditingController(text: widget.stageData['stageDescription'] ?? '');
    _questions = widget.questions.map((question) {
      Map<String, dynamic> formattedQuestion = {
        'type': question['type'] ?? 'Identification',
        'question': question['question'] ?? '',
      };
  
      switch (formattedQuestion['type']) {
        case 'Matching Type':
          formattedQuestion['section1'] = question['section1'] ?? [];
          formattedQuestion['section2'] = question['section2'] ?? [];
          formattedQuestion['answerPairs'] = question['answerPairs'] ?? [];
          break;
        case 'Fill in the Blanks':
          formattedQuestion['options'] = question['options'] ?? [];
          formattedQuestion['answer'] = (question['answer'] is List) ? List<int>.from(question['answer']) : [];
          break;
        case 'Identification':
          formattedQuestion['answer'] = question['answer'] ?? '';
          formattedQuestion['answerLength'] = question['answerLength'] ?? 0;
          formattedQuestion['options'] = question['options'] ?? [];
          formattedQuestion['space'] = question['space'] ?? [];
          break;
        case 'Multiple Choice':
          formattedQuestion['answer'] = question['answer'] ?? '';
          formattedQuestion['options'] = question['options'] ?? [];
          break;
        default:
          formattedQuestion['answer'] = question['answer'] ?? '';
          formattedQuestion['answerLength'] = question['answerLength'] ?? 0;
          formattedQuestion['options'] = question['options'] ?? [];
          formattedQuestion['space'] = question['space'] ?? [];
          formattedQuestion['section1'] = question['section1'] ?? [];
          formattedQuestion['section2'] = question['section2'] ?? [];
          formattedQuestion['answerPairs'] = question['answerPairs'] ?? [];
          break;
      }
  
      return formattedQuestion;
    }).toList();
  }

  void _addQuestion(String type) {
    setState(() {
      Map<String, dynamic> newQuestion = {
        'type': type,
        'question': widget.language == 'fil' ? 'Ilagay ang iyong tanong dito' : 'Enter your question here',
      };

      switch (type) {
        case 'Multiple Choice':
          newQuestion.addAll({
            'options': widget.language == 'fil' 
                ? ['Pagpipilian 1', 'Pagpipilian 2', 'Pagpipilian 3', 'Pagpipilian 4']
                : ['Option 1', 'Option 2', 'Option 3', 'Option 4'],
            'answer': 0,
          });
          break;

        case 'Fill in the Blanks':
          newQuestion.addAll({
            'options': widget.language == 'fil'
                ? ['Salita 1', 'Salita 2', 'Salita 3', 'Salita 4']
                : ['Word 1', 'Word 2', 'Word 3', 'Word 4'],
            'answer': [0, 1],
          });
          break;

        case 'Matching Type':
          newQuestion.addAll({
            'section1': widget.language == 'fil'
                ? ['Aytem 1', 'Aytem 2', 'Aytem 3']
                : ['Item 1', 'Item 2', 'Item 3'],
            'section2': widget.language == 'fil'
                ? ['Tugma 1', 'Tugma 2', 'Tugma 3']
                : ['Match 1', 'Match 2', 'Match 3'],
            'answerPairs': widget.language == 'fil'
                ? [
                    {'section1': 'Aytem 1', 'section2': 'Tugma 1'},
                    {'section1': 'Aytem 2', 'section2': 'Tugma 2'},
                    {'section1': 'Aytem 3', 'section2': 'Tugma 3'},
                  ]
                : [
                    {'section1': 'Item 1', 'section2': 'Match 1'},
                    {'section1': 'Item 2', 'section2': 'Match 2'},
                    {'section1': 'Item 3', 'section2': 'Match 3'},
                  ],
          });
          break;

        case 'Identification':
          newQuestion.addAll({
            'answer': widget.language == 'fil' ? 'Sagot' : 'Answer',
            'answerLength': widget.language == 'fil' ? 5 : 6,
            'options': widget.language == 'fil' 
                ? ['S', 'A', 'G', 'O', 'T']
                : ['A', 'N', 'S', 'W', 'E', 'R'],
            'space': widget.language == 'fil' ? [5] : [6],
          });
          break;
      }

      _questions.add(newQuestion);
    });
  }

  void _saveStage() async {
    if (_formKey.currentState!.validate()) {
      try {
        final stageName = _stageNameController.text;
        final stageDescription = _stageDescriptionController.text;
        
        if (stageName.isEmpty || _questions.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter a stage name and add at least one question.'))
          );
          return;
        }

        // Create a complete stage data object
        final Map<String, dynamic> stageData = {
          'stageName': stageName,
          'stageDescription': stageDescription,
          'questions': _questions,
          'totalQuestions': _questions.length,
          'maxScore': _questions.length, // Assuming 1 point per question
          'lastModified': DateTime.now().millisecondsSinceEpoch,
        };

        // Update the stage with complete data
        await _stageService.updateStage(
          widget.language,
          widget.category,
          stageName,
          stageData,
        );

        // Force refresh the stage list in AdminStagePage
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stage updated successfully.'))
        );

        // Pop and return true to indicate successful update
        Navigator.pop(context, true);
      } catch (e) {
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving stage: $e'))
        );
      }
    }
  }

  void _editQuestion(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return EditQuestionDialog(
          question: _questions[index],
          onSave: (updatedQuestion) {
            setState(() {
              _questions[index] = updatedQuestion;
            });
          },
        );
      },
    );
  }

  void _removeQuestion(int index) {
    setState(() {
      _questions.removeAt(index);
    });
  }

  List<String> _getAnswerOptions(Map<String, dynamic> question) {
    if (question['type'] == 'Identification') {
      return [question['answer']]; // Return the answer as a single string
    } else if (question['answer'] is int) {
      int index = question['answer'];
      if (index >= 0 && index < question['options'].length) {
        return [question['options'][index].toString()];
      }
    } else if (question['answer'] is List) {
      if (question['type'] == 'Fill in the Blanks') {
        // Handle Fill in the Blanks type
        List<String> answers = (question['answer'] as List<dynamic>).map<String>((e) => e.toString()).toList();
        return answers
            .where((answer) => int.tryParse(answer) != null && int.parse(answer) >= 0 && int.parse(answer) < question['options'].length)
            .map<String>((answer) => question['options'][int.parse(answer)].toString())
            .toList();
      } else {
        // Handle other types
        List<int> indices = (question['answer'] as List<dynamic>).map<int>((e) => e as int).toList();
        return indices
            .where((index) => index >= 0 && index < question['options'].length)
            .map<String>((index) => question['options'][index].toString())
            .toList();
      }
    } else if (question['type'] == 'Matching Type') {
      return (question['answerPairs'] as List<dynamic>)
          .map<String>((pair) => '${pair['section1']} - ${pair['section2']}')
          .toList();
    }
    return [];
  }

  Future<bool> _onWillPop() async {
    return (await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirm Exit'),
            content: const Text('Do you wish to exit this page? Your changes will be lost!'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Yes'),
              ),
            ],
          ),
        )) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: const Color(0xFF381c64),
        appBar: AppBar(
          title: Text('Edit Stage', style: GoogleFonts.vt323(color: Colors.white, fontSize: 30)),
          backgroundColor: const Color(0xFF381c64),
          iconTheme: const IconThemeData(color: Colors.white), // Set the back button color to white
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: SvgPicture.asset(
                'assets/backgrounds/background.svg',
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center, // Center the row
                      children: [
                      SizedBox(
                        width: 200, // Set a fixed width for the stage name field
                        child: TextFormField(
                        controller: _stageNameController,
                        decoration: InputDecoration(
                          labelText: 'Stage Name',
                          labelStyle: GoogleFonts.vt323(color: Colors.white, fontSize: 20),
                          filled: true,
                          fillColor: Colors.transparent,
                          border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(0.0),
                          borderSide: const BorderSide(color: Colors.black, width: 2.0),
                          ),
                          enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(0.0),
                          borderSide: const BorderSide(color: Colors.black, width: 2.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(0.0),
                          borderSide: const BorderSide(color: Colors.black, width: 2.0),
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                          return 'Please enter a stage name';
                          }
                          return null;
                        },
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 400, // Set a fixed width for the stage name field
                        child: TextFormField(
                        controller: _stageDescriptionController,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          labelStyle: GoogleFonts.vt323(color: Colors.white, fontSize: 20),
                          filled: true,
                          fillColor: Colors.transparent,
                          border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(0.0),
                          borderSide: const BorderSide(color: Colors.black, width: 2.0),
                          ),
                          enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(0.0),
                          borderSide: const BorderSide(color: Colors.black, width: 2.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(0.0),
                          borderSide: const BorderSide(color: Colors.black, width: 2.0),
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                          return 'Please enter a description';
                          }
                          return null;
                        },
                        ),
                      ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    buildQuestionButtons(_addQuestion),
                    const SizedBox(height: 20),
                    Expanded(
                      child: Center(
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width * 0.6, // 60% of screen width
                          child: GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: 3, // Adjusted to make the cards shorter
                            ),
                            itemCount: _questions.length,
                            itemBuilder: (context, index) => buildQuestionCard(index, _questions, _editQuestion, _removeQuestion, _getAnswerOptions),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _saveStage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF1B33A),
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(0.0),
                          side: const BorderSide(color: Colors.black, width: 2.0),
                        ),
                      ),
                      child: Text('Save Stage', style: GoogleFonts.vt323(color: Colors.black, fontSize: 20)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}