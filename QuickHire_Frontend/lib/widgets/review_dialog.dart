import 'package:flutter/material.dart';

class ReviewDialog extends StatefulWidget {
  final Function(int, String) onSubmit;
  const ReviewDialog({required this.onSubmit, super.key});
  @override
  State<ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<ReviewDialog> {
  int _rating = 5;
  final _controller = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Submit Review'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Rate this project:'),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) => IconButton(
              icon: Icon(i < _rating ? Icons.star : Icons.star_border, color: Colors.amber),
              onPressed: () => setState(() => _rating = i + 1),
            )),
          ),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(hintText: 'Write a comment...'),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.white),
          onPressed: () {
            widget.onSubmit(_rating, _controller.text.trim());
          },
          child: const Text('Submit'),
        ),
      ],
    );
  }
}