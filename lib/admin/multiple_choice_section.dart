import 'package:flutter/material.dart';

class MultipleChoiceSection extends StatelessWidget {
  final Map<String, dynamic> question;
  final List<TextEditingController> optionControllers;
  final VoidCallback addOption;
  final ValueChanged<int> removeOption;
  final ValueChanged<String> onAnswerChanged;
  final ValueChanged<String> onQuestionChanged; // Add this callback

  const MultipleChoiceSection({
    super.key,
    required this.question,
    required this.optionControllers,
    required this.addOption,
    required this.removeOption,
    required this.onAnswerChanged,
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
                SizedBox(height: 8.0), // Add margin between fields
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.20, // Set width to 20% of the available width
                  child: TextFormField(
                    initialValue: question['answer'].toString(),
                    decoration: InputDecoration(labelText: 'Answer (index)'),
                    onChanged: onAnswerChanged,
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
                  children: List.generate(optionControllers.length, (index) {
                    return SizedBox(
                      width: (MediaQuery.of(context).size.width - 64) * 0.1, // Adjust width for 35% of the available width
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: optionControllers[index],
                              decoration: InputDecoration(labelText: 'Option ${index + 1}'),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () => removeOption(index),
                          ),
                        ],
                      ),
                    );
                  }),
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
      ],
    );
  }
}