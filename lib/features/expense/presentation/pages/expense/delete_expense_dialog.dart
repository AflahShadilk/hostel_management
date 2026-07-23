import 'package:flutter/material.dart';

class DeleteExpenseDialog extends StatelessWidget {
  final String title;
  final String message;

  const DeleteExpenseDialog({
    super.key,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      );
}
