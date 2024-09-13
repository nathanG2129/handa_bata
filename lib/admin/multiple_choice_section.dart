import 'package:flutter/material.dart';

class MultipleChoiceSection extends StatelessWidget {
  final Map<String, dynamic> question;
  final List<TextEditingController> optionControllers;
  final VoidCallback addOption;
  final ValueChanged<int> removeOption;
  final ValueChanged<String> onAnswerChanged;

  const MultipleChoiceSection({
    super.key,
    required this.question,
    required this.optionControllers,
    required this.addOption,
    required this.removeOption,
    required this.onAnswerChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          initialValue: question['answer'].toString(),
          decoration: InputDecoration(labelText: 'Answer (index)'),
          onChanged: onAnswerChanged,
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
      ],
    );
  }
}