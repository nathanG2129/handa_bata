import 'package:flutter/material.dart';

class FillInTheBlanksSection extends StatelessWidget {
  final Map<String, dynamic> question;
  final List<TextEditingController> optionControllers;
  final VoidCallback addOption;
  final ValueChanged<int> removeOption;
  final void Function(int, int) onAnswerChanged; // Updated signature
  final void Function(int, String) onOptionChanged; // Updated signature

  FillInTheBlanksSection({
    required this.question,
    required this.optionControllers,
    required this.addOption,
    required this.removeOption,
    required this.onAnswerChanged,
    required this.onOptionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Options:'),
        ...optionControllers.map((controller) {
          int index = optionControllers.indexOf(controller);
          return Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: controller,
                  decoration: InputDecoration(labelText: 'Option ${index + 1}'),
                  onChanged: (value) => onOptionChanged(index, value), // Updated call
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
        Text('Correct Answers (Indexes):'),
        ...List.generate(question['answer'].length, (index) {
          return Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: question['answer'][index].toString(),
                  decoration: InputDecoration(labelText: 'Answer Index ${index + 1}'),
                  onChanged: (value) => onAnswerChanged(index, int.tryParse(value) ?? 0), // Updated call
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete),
                onPressed: () {
                  question['answer'].removeAt(index);
                  (context as Element).markNeedsBuild(); // Force rebuild to update UI
                },
              ),
            ],
          );
        }),
        ElevatedButton(
          onPressed: () {
            question['answer'].add(0);
            (context as Element).markNeedsBuild(); // Force rebuild to update UI
          },
          child: Text('Add Answer Index'),
        ),
      ],
    );
  }
}