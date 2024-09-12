import 'package:flutter/material.dart';

class QuestionListItem extends StatelessWidget {
  final Map<String, dynamic> question;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const QuestionListItem({
    super.key,
    required this.question,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text('Question ${index + 1}'),
      subtitle: Text(question['type']),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: onEdit,
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}