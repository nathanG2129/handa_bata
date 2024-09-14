import 'package:flutter/material.dart';

class FillInTheBlanksSection extends StatelessWidget {
  final Map<String, dynamic> question;
  final List<TextEditingController> optionControllers;
  final VoidCallback addOption;
  final ValueChanged<int> removeOption;
  final void Function(int, int) onAnswerChanged; // Updated signature
  final void Function(int, String) onOptionChanged; // Updated signature
  final ValueChanged<String> onQuestionChanged; // Add this callback

  FillInTheBlanksSection({
    required this.question,
    required this.optionControllers,
    required this.addOption,
    required this.removeOption,
    required this.onAnswerChanged,
    required this.onOptionChanged,
    required this.onQuestionChanged, // Add this parameter
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 16.0), // Add margin above the question details
        Card(
          margin: EdgeInsets.all(8.0),
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Question Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8.0),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.20, // Set width to 20% of the available width
                  child: TextFormField(
                    initialValue: question['question'],
                    decoration: InputDecoration(labelText: 'Question'),
                    onChanged: onQuestionChanged, // Use the callback
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 16.0), // Add margin between sections
        Card(
          margin: EdgeInsets.all(8.0),
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Options',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8.0),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: optionControllers.map((controller) {
                    int index = optionControllers.indexOf(controller);
                    return SizedBox(
                      width: (MediaQuery.of(context).size.width - 64) * 0.1, // Adjust width for 10% of the available width
                      child: Row(
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
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 8.0),
                ElevatedButton(
                  onPressed: addOption,
                  child: Text('Add Option'),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 16.0), // Add margin between sections
        Card(
          margin: EdgeInsets.all(8.0),
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Correct Answers (Indexes)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8.0),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: List.generate(question['answer'].length, (index) {
                    return SizedBox(
                      width: (MediaQuery.of(context).size.width - 64) * 0.1, // Adjust width for 10% of the available width
                      child: Row(
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
                      ),
                    );
                  }),
                ),
                SizedBox(height: 8.0),
                ElevatedButton(
                  onPressed: () {
                    question['answer'].add(0);
                    (context as Element).markNeedsBuild(); // Force rebuild to update UI
                  },
                  child: Text('Add Answer Index'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}