import 'package:flutter/material.dart';

class IdentificationSection extends StatelessWidget {
  final Map<String, dynamic> question;
  final List<TextEditingController> optionControllers;
  final VoidCallback addOption;
  final ValueChanged<int> removeOption;
  final ValueChanged<String> onAnswerChanged;
  final ValueChanged<String> onAnswerLengthChanged;
  final ValueChanged<String> onSpaceChanged;

  const IdentificationSection({
    super.key,
    required this.question,
    required this.optionControllers,
    required this.addOption,
    required this.removeOption,
    required this.onAnswerChanged,
    required this.onAnswerLengthChanged,
    required this.onSpaceChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          initialValue: question['answer'],
          decoration: InputDecoration(labelText: 'Answer'),
          onChanged: onAnswerChanged,
        ),
        TextFormField(
          initialValue: question['answerLength'].toString(),
          decoration: InputDecoration(labelText: 'Answer Length'),
          onChanged: onAnswerLengthChanged,
        ),
        ...optionControllers.map((controller) {
          int index = optionControllers.indexOf(controller);
          return Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: controller,
                  decoration: InputDecoration(labelText: 'Option ${index + 1}'),
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete),
                onPressed: () => removeOption(index),
              ),
            ],
          );
        }).toList(),
        ElevatedButton(
          onPressed: addOption,
          child: Text('Add Option'),
        ),
        TextFormField(
          initialValue: (question['space'] as List<dynamic>?)?.join(', ') ?? '',
          decoration: InputDecoration(labelText: 'Space (comma separated)'),
          onChanged: onSpaceChanged,
        ),
      ],
    );
  }
}