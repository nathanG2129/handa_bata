import 'package:flutter/material.dart';

class MatchingTypeSection extends StatefulWidget {
  final Map<String, dynamic> question;
  final List<TextEditingController> optionControllersSection1;
  final List<TextEditingController> optionControllersSection2;
  final List<Map<String, String>> answerPairs;
  final VoidCallback addOptionSection1;
  final VoidCallback addOptionSection2;
  final ValueChanged<int> removeOptionSection1;
  final ValueChanged<int> removeOptionSection2;
  final ValueChanged<int> removeAnswerPair;
  final ValueChanged<Map<String, String>> addAnswerPair;

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
        Text('Options Section 1:'),
        ...widget.optionControllersSection1.map((controller) {
          int index = widget.optionControllersSection1.indexOf(controller);
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
                onPressed: () => widget.removeOptionSection1(index),
              ),
            ],
          );
        }).toList(),
        ElevatedButton(
          onPressed: widget.addOptionSection1,
          child: Text('Add Option to Section 1'),
        ),
        Text('Options Section 2:'),
        ...widget.optionControllersSection2.map((controller) {
          int index = widget.optionControllersSection2.indexOf(controller);
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
                onPressed: () => widget.removeOptionSection2(index),
              ),
            ],
          );
        }).toList(),
        ElevatedButton(
          onPressed: widget.addOptionSection2,
          child: Text('Add Option to Section 2'),
        ),
        Text('Answer Pairs:'),
        ...widget.answerPairs.map((pair) {
          int index = widget.answerPairs.indexOf(pair);
          return Row(
            children: [
              Expanded(
                child: Text('${pair['section1']} - ${pair['section2']}'),
              ),
              IconButton(
                icon: Icon(Icons.delete),
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
                items: widget.question['section1']
                    .map<DropdownMenuItem<String>>((option) => DropdownMenuItem<String>(
                          value: option,
                          child: Text(option),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedSection1Option = value;
                  });
                },
                decoration: InputDecoration(labelText: 'Section 1 Option'),
              ),
            ),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: selectedSection2Option,
                items: widget.question['section2']
                    .map<DropdownMenuItem<String>>((option) => DropdownMenuItem<String>(
                          value: option,
                          child: Text(option),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedSection2Option = value;
                  });
                },
                decoration: InputDecoration(labelText: 'Section 2 Option'),
              ),
            ),
            IconButton(
              icon: Icon(Icons.add),
              onPressed: selectedSection1Option != null && selectedSection2Option != null
                  ? () => widget.addAnswerPair({'section1': selectedSection1Option!, 'section2': selectedSection2Option!})
                  : null,
            ),
          ],
        ),
      ],
    );
  }
}