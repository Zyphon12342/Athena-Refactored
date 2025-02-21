import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../messages/message_bubble.dart';

class ChatList extends StatelessWidget {
  final List<Map<String, dynamic>> messages;
  final ScrollController scrollController;
  final double maxBubbleWidth;

  const ChatList({
    super.key,
    required this.messages,
    required this.scrollController,
    required this.maxBubbleWidth,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(10),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[index];
        final String sender = msg["sender"] ?? "bot";
        final bool isUser = sender == "user";

        Widget bubble;
        switch (msg["type"]) {
          case "text":
            bubble = ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxBubbleWidth),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isUser ? Colors.purpleAccent : Colors.grey[800],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  msg["text"].toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 20),
                ),
              ),
            ).animate().fade(duration: 300.ms).slideX(
                  begin: isUser ? 1 : -1,
                );
            break;
          case "image":
            bubble = ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxBubbleWidth,
                maxHeight: 250,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(File(msg["imagePath"]), fit: BoxFit.cover),
              ),
            );
            break;
          case "loading":
            bubble = ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxBubbleWidth),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
              ),
            ).animate().fade(duration: 300.ms).slideX(
                  begin: isUser ? 1 : -1,
                );
            break;
          // For card types and others, assume msg["data"] is a widget.
          default:
            bubble = msg["data"];
            break;
        }
        return buildMessageWithIcon(
          messageWidget: bubble,
          index: index,
          messages: messages,
          isUser: isUser,
        );
      },
    );
  }
}
