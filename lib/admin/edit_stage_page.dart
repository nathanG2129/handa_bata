import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/stage_service.dart';
import 'admin_widgets/edit_question_dialog.dart';

class EditStagePage extends StatefulWidget {
  final String language;
  final String category;
  final String stageName;
  final List<Map<String, dynamic>> questions;

  const EditStagePage({super.key, required this.language, required this.category, required this.stageName, required this.questions});

  @override
  _EditStagePageState createState() => _EditStagePageState();
}

class _EditStagePageState extends State<EditStagePage> {
  final _formKey = GlobalKey<FormState>();
  final StageService _stageService = StageService();
  late TextEditingController _stageNameController;
  late List<Map<String, dynamic>> _questions;

  @override
  void initState() {
    super.initState();
    _stageNameController = TextEditingController(text: widget.stageName);
    _questions = widget.questions.map((question) {
      return {
        'type': question['type'] ?? 'Identification',
        'question': question['question'] ?? '',
        'answer': question['answer'] ?? '',
        'answerLength': question['answerLength'] ?? 0,
        'options': question['options'] ?? [],
        'space': question['space'] ?? [],
        'section1': question['section1'] ?? [],
        'section2': question['section2'] ?? [],
        'answerPairs': question['answerPairs'] ?? [],
      };
    }).toList();
  }

  void _addQuestion(String type) {
    setState(() {
      _questions.add({
        'type': type,
        'question': '',
        'answer': '',
        'answerLength': 0,
        'options': [],
        'space': [],
        'section1': [],
        'section2': [],
        'answerPairs': [],
      });
    });
  }

  void _saveStage() async {
    final stageName = _stageNameController.text;
    if (stageName.isNotEmpty && _questions.isNotEmpty) {
      await _stageService.updateStage(widget.language, widget.category, stageName, {
        'stageName': stageName,
        'questions': _questions,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stage updated successfully.')));
        Navigator.pop(context); // Go back to the previous page
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a stage name and add at least one question.')));
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

    Widget _buildQuestionCard(int index) {
    final question = _questions[index];
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0.0), // Square corners
        side: const BorderSide(color: Colors.black, width: 2.0), // Black border
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'Question ${index + 1}: ${question['question']}',
                    style: GoogleFonts.vt323(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 20),
                  ),
                ),
                Text(
                  question['type'],
                  style: GoogleFonts.vt323(fontStyle: FontStyle.italic, color: Colors.black, fontSize: 20),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (question['type'] == 'Matching Type') ...[
                            Text('Section 1 Options:', style: GoogleFonts.vt323(color: Colors.black, fontSize: 20)),
                            ...question['section1'].map<Widget>((option) => Text(option, style: GoogleFonts.vt323(color: Colors.black, fontSize: 20))).toList(),
                            const SizedBox(height: 8.0),
                            Text('Section 2 Options:', style: GoogleFonts.vt323(color: Colors.black, fontSize: 20)),
                            ...question['section2'].map<Widget>((option) => Text(option, style: GoogleFonts.vt323(color: Colors.black, fontSize: 20))).toList(),
                          ],
                          if (question['type'] != 'Matching Type' && question['options'] != null && question['options'].isNotEmpty)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Options:', style: GoogleFonts.vt323(color: Colors.black, fontSize: 20)),
                                Wrap(
                                  spacing: 8.0, // Space between items
                                  runSpacing: 4.0, // Space between lines
                                  children: question['options'].map<Widget>((option) {
                                    return Text('- $option', style: GoogleFonts.vt323(color: Colors.black, fontSize: 20));
                                  }).toList(),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16.0), // Add some spacing between the columns
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (question['answer'] != null)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Answer:', style: GoogleFonts.vt323(color: Colors.black, fontSize: 20)),
                                ..._getAnswerOptions(question).map<Widget>((option) {
                                  return Text(option, style: GoogleFonts.vt323(color: Colors.black, fontSize: 20)); // Display the answer as a single string
                                }).toList(),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editQuestion(index),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _removeQuestion(index),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: () => _addQuestion('Multiple Choice'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF381c64),
            shadowColor: Colors.transparent,
          ),
          child: Text('Add Multiple Choice', style: GoogleFonts.vt323(color: Colors.white, fontSize: 20)),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: () => _addQuestion('Fill in the Blanks'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF381c64),
            shadowColor: Colors.transparent,
          ),
          child: Text('Add Fill in the Blanks', style: GoogleFonts.vt323(color: Colors.white, fontSize: 20)),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: () => _addQuestion('Matching Type'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF381c64),
            shadowColor: Colors.transparent,
          ),
          child: Text('Add Matching Type', style: GoogleFonts.vt323(color: Colors.white, fontSize: 20)),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: () => _addQuestion('Identification'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF381c64),
            shadowColor: Colors.transparent,
          ),
          child: Text('Add Identification', style: GoogleFonts.vt323(color: Colors.white, fontSize: 20)),
        ),
      ],
    );
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
                      Center(
                        child: Container(
                          width: 300,
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
                      ),
                      const SizedBox(height: 20),
                      _buildQuestionButtons(),
                      const SizedBox(height: 20),
                      Expanded(
                        child: Center(
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.6, // 60% of screen width
                            child: GridView.builder(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                childAspectRatio: 3, // Adjusted to make the cards shorter
                              ),
                              itemCount: _questions.length,
                              itemBuilder: (context, index) => _buildQuestionCard(index),
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
                        child: Text('Save Stage', style: GoogleFonts.vt323(color: Colors.white, fontSize: 20)),
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