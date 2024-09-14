import 'package:flutter/material.dart';
import 'matching_type_section.dart';
import 'multiple_choice_section.dart';
import 'identification_section.dart';
import 'fill_in_the_blanks_section.dart'; // Import the new file

class EditQuestionDialog extends StatefulWidget {
  final Map<String, dynamic> question;
  final Function(Map<String, dynamic>) onSave;

  const EditQuestionDialog({super.key, required this.question, required this.onSave});

  @override
  _EditQuestionDialogState createState() => _EditQuestionDialogState();
}

class _EditQuestionDialogState extends State<EditQuestionDialog> {
  late Map<String, dynamic> _question;
  late List<TextEditingController> _optionControllers;
  late List<TextEditingController> _optionControllersSection1;
  late List<TextEditingController> _optionControllersSection2;
  late List<Map<String, String>> _answerPairs;

  @override
  void initState() {
    super.initState();
    _question = Map<String, dynamic>.from(widget.question);
    _initializeControllers();
  }

  void _initializeControllers() {
    _optionControllersSection1 = [];
    _optionControllersSection2 = [];
    _answerPairs = [];
    _optionControllers = [];

    // Initialize controllers based on the question type
    if (_question['type'] == 'Matching Type') {
      _optionControllersSection1 = _createControllers(_question['section1'] ?? []);
      _optionControllersSection2 = _createControllers(_question['section2'] ?? []);
      _answerPairs = List<Map<String, String>>.from(_question['answerPairs']?.map((pair) => Map<String, String>.from(pair)) ?? []);
      _question.remove('answer'); // Remove unnecessary fields
      _question.remove('answerLength');
      _question.remove('space');
      _question.remove('options');
    } else if (_question['type'] == 'Fill in the Blanks') {
      _optionControllers = _createControllers(_question['options'] ?? []);
      _question['answer'] = (_question['answer'] is List) ? List<int>.from(_question['answer']) : [];
      _question.remove('answerLength'); // Remove unnecessary fields
      _question.remove('space');
      _question.remove('section1');
      _question.remove('section2');
      _question.remove('answerPairs');
    } else if (_question['type'] == 'Identification') {
      _optionControllers = _createControllers(_question['options'] ?? []);
      _question['answer'] = _question['answer'] ?? '';
      _question['answerLength'] = _question['answerLength'] ?? 0; // Ensure necessary fields are present
      _question['space'] = _question['space'] ?? [];
      _question.remove('section1'); // Remove unnecessary fields
      _question.remove('section2');
      _question.remove('answerPairs');
    } else if (_question['type'] == 'Multiple Choice') {
      _optionControllers = _createControllers(_question['options'] ?? []);
      _question['answer'] = _question['answer'] ?? '';
      _question.remove('answerLength'); // Remove unnecessary fields
      _question.remove('space');
      _question.remove('section1');
      _question.remove('section2');
      _question.remove('answerPairs');
    }
  }

  List<TextEditingController> _createControllers(List<dynamic> items) {
    return List.generate(items.length, (index) => TextEditingController(text: items[index]));
  }

  void _addOption(List<TextEditingController> controllers, List<dynamic> items) {
    setState(() {
      items.add('');
      controllers.add(TextEditingController());
    });
  }

  void _removeOption(List<TextEditingController> controllers, List<dynamic> items, int index) {
    setState(() {
      items.removeAt(index);
      controllers.removeAt(index);
    });
  }

  void _save() {
    if (_question['type'] == 'Matching Type') {
      _question['section1'] = _optionControllersSection1.map((controller) => controller.text).toList();
      _question['section2'] = _optionControllersSection2.map((controller) => controller.text).toList();
      _question['answerPairs'] = _answerPairs;
      _question.remove('answer'); // Remove unnecessary fields
      _question.remove('answerLength');
      _question.remove('space');
      _question.remove('options');
    } else if (_question['type'] == 'Fill in the Blanks') {
      _question['options'] = _optionControllers.map((controller) => controller.text).toList();
      _question['answer'] = (_question['answer'] is List) ? List<int>.from(_question['answer']) : [];
      _question.remove('answerLength'); // Remove unnecessary fields
      _question.remove('space');
      _question.remove('section1');
      _question.remove('section2');
      _question.remove('answerPairs');
    } else if (_question['type'] == 'Identification') {
      _question['options'] = _optionControllers.map((controller) => controller.text).toList();
      _question['answer'] = _question['answer'] ?? '';
      _question['answerLength'] = _question['answerLength'] ?? 0; // Ensure necessary fields are present
      _question['space'] = _question['space'] ?? [];
      _question.remove('section1'); // Remove unnecessary fields
      _question.remove('section2');
      _question.remove('answerPairs');
    } else if (_question['type'] == 'Multiple Choice') {
      _question['options'] = _optionControllers.map((controller) => controller.text).toList();
      _question['answer'] = _question['answer'] ?? '';
      _question.remove('answerLength'); // Remove unnecessary fields
      _question.remove('space');
      _question.remove('section1');
      _question.remove('section2');
      _question.remove('answerPairs');
    }
    widget.onSave(_question);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    bool isNewQuestion = widget.question['id'] == null; // Assuming 'id' is null for new questions

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.35, // Set dialog width to 35% of screen width
        child: AlertDialog(
          title: Text('Edit Question'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                if (_question['type'] == 'Identification')
                  IdentificationSection(
                    question: _question,
                    optionControllers: _optionControllers,
                    addOption: () => _addOption(_optionControllers, _question['options']),
                    removeOption: (index) => _removeOption(_optionControllers, _question['options'], index),
                    onAnswerChanged: (value) => setState(() => _question['answer'] = value),
                    onAnswerLengthChanged: (value) => setState(() => _question['answerLength'] = int.tryParse(value) ?? 0),
                    onSpaceChanged: (value) => setState(() => _question['space'] = value.split(',').map((e) => e.trim()).toList()),
                    onQuestionChanged: (value) => setState(() => _question['question'] = value), // Pass the callback
                  ),
                if (_question['type'] == 'Multiple Choice')
                  MultipleChoiceSection(
                    question: _question,
                    optionControllers: _optionControllers,
                    addOption: () => _addOption(_optionControllers, _question['options']),
                    removeOption: (index) => _removeOption(_optionControllers, _question['options'], index),
                    onAnswerChanged: (value) => setState(() => _question['answer'] = int.tryParse(value) ?? 0),
                    onQuestionChanged: (value) => setState(() => _question['question'] = value), // Pass the callback
                  ),
                if (_question['type'] == 'Fill in the Blanks')
                  FillInTheBlanksSection(
                    question: _question,
                    optionControllers: _optionControllers,
                    addOption: () => _addOption(_optionControllers, _question['options']),
                    removeOption: (index) => _removeOption(_optionControllers, _question['options'], index),
                    onAnswerChanged: (index, value) => setState(() => _question['answer'][index] = int.tryParse(value as String) ?? 0), // Updated call
                    onOptionChanged: (index, value) => setState(() => _question['options'][index] = value), // Updated call
                    onQuestionChanged: (value) => setState(() => _question['question'] = value), // Pass the callback
                  ),
                if (_question['type'] == 'Matching Type')
                  MatchingTypeSection(
                    question: _question,
                    optionControllersSection1: _optionControllersSection1,
                    optionControllersSection2: _optionControllersSection2,
                    answerPairs: _answerPairs,
                    addOptionSection1: () => _addOption(_optionControllersSection1, _question['section1']),
                    addOptionSection2: () => _addOption(_optionControllersSection2, _question['section2']),
                    removeOptionSection1: (index) => _removeOption(_optionControllersSection1, _question['section1'], index),
                    removeOptionSection2: (index) => _removeOption(_optionControllersSection2, _question['section2'], index),
                    removeAnswerPair: (index) => setState(() => _answerPairs.removeAt(index)),
                    addAnswerPair: (pair) => setState(() => _answerPairs.add(pair)),
                    onQuestionChanged: (value) => setState(() => _question['question'] = value), // Pass the callback
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: _save,
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}