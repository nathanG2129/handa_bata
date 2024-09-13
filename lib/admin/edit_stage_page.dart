import 'package:flutter/material.dart';
import '../services/stage_service.dart';
import 'edit_question_dialog.dart';
import 'question_list_item.dart';

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
  late String _stageName;
  late List<Map<String, dynamic>> _questions;

  @override
  void initState() {
    super.initState();
    _stageNameController = TextEditingController(text: widget.stageName);
    _questions = List<Map<String, dynamic>>.from(widget.questions);
    _stageName = widget.stageName;
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

  void _addQuestion() {
    setState(() {
      _questions.add({
        'type': 'Identification',
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Stage updated successfully.')));
      Navigator.pop(context); // Go back to the previous page
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please enter a stage name and add at least one question.')));
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
      List<int> indices = (question['answer'] as List<dynamic>).map<int>((e) => e as int).toList();
      return indices
          .where((index) => index >= 0 && index < question['options'].length)
          .map<String>((index) => question['options'][index].toString())
          .toList();
    } else if (question['type'] == 'Matching Type') {
      return (question['answerPairs'] as List<dynamic>)
          .map<String>((pair) => '${pair['section1']} - ${pair['section2']}')
          .toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Stage'),
      ),
      body: Padding(
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
                    decoration: InputDecoration(labelText: 'Stage Name'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a stage name';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _stageName = value!;
                    },
                  ),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _addQuestion,
                child: Text('Add Question'),
              ),
              SizedBox(height: 20),
              Expanded(
                child: Center(
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.6, // 60% of screen width
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 3, // Adjusted to make the cards shorter
                      ),
                      itemCount: _questions.length,
                      itemBuilder: (context, index) {
                        final question = _questions[index];
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 8.0),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Question ${index + 1}: ${question['question']}',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 8.0),
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
                                                Text('Section 1 Options:'),
                                                ...question['section1'].map<Widget>((option) => Text(option)).toList(),
                                                SizedBox(height: 8.0),
                                                Text('Section 2 Options:'),
                                                ...question['section2'].map<Widget>((option) => Text(option)).toList(),
                                              ],
                                              if (question['type'] != 'Matching Type' && question['options'] != null && question['options'].isNotEmpty)
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text('Options:'),
                                                    Wrap(
                                                      spacing: 8.0, // Space between items
                                                      runSpacing: 4.0, // Space between lines
                                                      children: question['options'].map<Widget>((option) {
                                                        return Text('- $option');
                                                      }).toList(),
                                                    ),
                                                  ],
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 16.0), // Add some spacing between the columns
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            if (question['answer'] != null)
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text('Answer:'),
                                                  ..._getAnswerOptions(question).map<Widget>((option) {
                                                    return Text(option); // Display the answer as a single string
                                                  }).toList(),
                                                ],
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.edit),
                                      onPressed: () => _editQuestion(index),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete),
                                      onPressed: () => _removeQuestion(index),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveStage,
                child: Text('Save Stage'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}