import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MatchingTypeSection extends StatefulWidget {
  final Map<String, dynamic> question;
  final List<TextEditingController> optionControllersSection1;
  final List<TextEditingController> optionControllersSection2;
  final List<Map<String, String>> answerPairs; // Changed to store options
  final VoidCallback addOptionSection1;
  final VoidCallback addOptionSection2;
  final ValueChanged<int> removeOptionSection1;
  final ValueChanged<int> removeOptionSection2;
  final ValueChanged<int> removeAnswerPair;
  final ValueChanged<Map<String, String>> addAnswerPair; // Changed to store options
  final ValueChanged<String> onQuestionChanged; // Added this callback

  const MatchingTypeSection({
    super.key,
    required this.question,
    required this.optionControllersSection1,
    required this.optionControllersSection2,
    required this.answerPairs,
    required this.addOptionSection1,
    required this.addOptionSection2,
    required this.removeOptionSection1,
    required this.removeOptionSection2,
    required this.removeAnswerPair,
    required this.addAnswerPair,
    required this.onQuestionChanged, // Added this parameter
  });

  @override
  _MatchingTypeSectionState createState() => _MatchingTypeSectionState();
}

class _MatchingTypeSectionState extends State<MatchingTypeSection> {
  String? selectedSection1Option;
  String? selectedSection2Option;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16.0), // Add margin above the question details
        Card(
          margin: const EdgeInsets.all(8.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Question Details',
                  style: GoogleFonts.vt323(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8.0),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.20, // Set width to 20% of the available width
                  child: TextFormField(
                    initialValue: widget.question['question'],
                    decoration: const InputDecoration(labelText: 'Question'),
                    onChanged: widget.onQuestionChanged, // Use the callback
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16.0), // Add margin between sections
        _buildOptionsSection(
          context,
          'Options Section 1',
          widget.optionControllersSection1,
          widget.addOptionSection1,
          widget.removeOptionSection1,
        ),
        const SizedBox(height: 16.0), // Add margin between sections
        _buildOptionsSection(
          context,
          'Options Section 2',
          widget.optionControllersSection2,
          widget.addOptionSection2,
          widget.removeOptionSection2,
        ),
        const SizedBox(height: 16.0), // Add margin between sections
        _buildAnswerPairsSection(context),
      ],
    );
  }

  Widget _buildOptionsSection(
    BuildContext context,
    String title,
    List<TextEditingController> optionControllers,
    VoidCallback addOption,
    ValueChanged<int> removeOption,
  ) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.vt323(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            ElevatedButton(
              onPressed: addOption,
              child: const Text('Add Option'),
            ),
            const SizedBox(height: 8.0),
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
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => removeOption(index),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerPairsSection(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Answer Pairs',
              style: GoogleFonts.vt323(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            ...widget.answerPairs.map((pair) {
              int index = widget.answerPairs.indexOf(pair);
              return Row(
                children: [
                  Expanded(
                    child: Text('${pair['section1']} - ${pair['section2']}'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => widget.removeAnswerPair(index),
                  ),
                ],
              );
            }).toList(),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedSection1Option,
                    items: widget.optionControllersSection1.map((controller) {
                      return DropdownMenuItem<String>(
                        value: controller.text,
                        child: Text(controller.text),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedSection1Option = value;
                      });
                    },
                    decoration: const InputDecoration(labelText: 'Section 1 Option'),
                  ),
                ),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedSection2Option,
                    items: widget.optionControllersSection2.map((controller) {
                      return DropdownMenuItem<String>(
                        value: controller.text,
                        child: Text(controller.text),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedSection2Option = value;
                      });
                    },
                    decoration: const InputDecoration(labelText: 'Section 2 Option'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: selectedSection1Option != null && selectedSection2Option != null
                      ? () {
                          widget.addAnswerPair({'section1': selectedSection1Option!, 'section2': selectedSection2Option!});
                          setState(() {
                            selectedSection1Option = null;
                            selectedSection2Option = null;
                          });
                        }
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}