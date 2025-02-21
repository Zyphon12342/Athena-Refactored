import 'package:flutter/material.dart';

class ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isLoading;
  final VoidCallback onSend;
  final VoidCallback onCancel;
  final VoidCallback onImagePick;

  const ChatInput({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isLoading,
    required this.onSend,
    required this.onCancel,
    required this.onImagePick,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(
            height: 56,
            width: 56,
            child: FloatingActionButton(
              backgroundColor: Colors.grey[900],
              onPressed: onImagePick,
              child: const Icon(Icons.photo, color: Colors.white),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              enabled: !isLoading,
              style: const TextStyle(color: Colors.white),
              onSubmitted: (_) => onSend(),
              textInputAction: TextInputAction.send,
              maxLines: null,
              decoration: InputDecoration(
                hintText: "Ask something...",
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: isLoading ? Colors.grey : Colors.grey[900],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 56,
            width: 56,
            child: FloatingActionButton(
              backgroundColor: isLoading ? Colors.red : Colors.purpleAccent,
              onPressed: isLoading ? onCancel : onSend,
              child: Icon(
                isLoading ? Icons.stop : Icons.send,
                size: 24,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
