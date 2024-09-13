import 'package:flutter/material.dart';
import 'matching_type_section.dart';
import 'multiple_choice_section.dart';
import 'identification_section.dart';
import 'question_type_dropdown.dart';

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
    _answerPairs = List<Map<String, String>>.from(_question['answerPairs']?.map((pair) => Map<String, String>.from(pair)) ?? []);
    if (_question['type'] == 'Matching Type') {
      _optionControllersSection1 = _createControllers(_question['section1']);
      _optionControllersSection2 = _createControllers(_question['section2']);
    } else {
      _optionControllers = _createControllers(_question['options']);
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
    } else {
      _question['options'] = _optionControllers.map((controller) => controller.text).toList();
    }
    widget.onSave(_question);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit Question'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            QuestionTypeDropdown(
              value: _question['type'],
              onChanged: (value) {
                setState(() {
                  _question['type'] = value!;
                  _initializeControllers();
                });
              },
            ),
            TextFormField(
              initialValue: _question['question'],
              decoration: InputDecoration(labelText: 'Question'),
              onChanged: (value) {
                _question['question'] = value;
              },
            ),
            if (_question['type'] == 'Identification')
              IdentificationSection(
                question: _question,
                optionControllers: _optionControllers,
                addOption: () => _addOption(_optionControllers, _question['options']),
                removeOption: (index) => _removeOption(_optionControllers, _question['options'], index),
                onAnswerChanged: (value) => setState(() => _question['answer'] = value),
                onAnswerLengthChanged: (value) => setState(() => _question['answerLength'] = int.tryParse(value) ?? 0),
                onSpaceChanged: (value) => setState(() => _question['space'] = value.split(',').map((e) => e.trim()).toList()),
              ),
            if (_question['type'] == 'Multiple Choice' || _question['type'] == 'Fill in the Blanks')
              MultipleChoiceSection(
                question: _question,
                optionControllers: _optionControllers,
                addOption: () => _addOption(_optionControllers, _question['options']),
                removeOption: (index) => _removeOption(_optionControllers, _question['options'], index),
                onAnswerChanged: (value) => setState(() => _question['answer'] = int.tryParse(value) ?? 0),
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
    );
  }
}