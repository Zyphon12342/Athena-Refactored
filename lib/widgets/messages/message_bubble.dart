import 'package:flutter/material.dart';

Widget buildMessageWithIcon({
  required Widget messageWidget,
  required int index,
  required List<Map<String, dynamic>> messages,
  required bool isUser,
}) {
  bool showIcon = true;
  if (index > 0) {
    final prevMsg = messages[index - 1];
    if (prevMsg["sender"] == messages[index]["sender"]) {
      showIcon = false;
    }
  }

  const double iconAreaWidth = 40.0;
  const double spacing = 8.0;
  Widget iconWidget;
  if (showIcon) {
    if (isUser) {
      iconWidget = Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.purpleAccent,
          ),
          padding: const EdgeInsets.all(4.0),
          alignment: Alignment.center,
          child: const Icon(
            Icons.person_rounded,
            size: 30.0,
            color: Colors.white,
          ),
        ),
      );
    } else {
      iconWidget = Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey[800],
          ),
          padding: const EdgeInsets.all(4.0),
          alignment: Alignment.center,
          child: const Icon(
            Icons.smart_toy_rounded,
            size: 30.0,
            color: Colors.white,
          ),
        ),
      );
    }
  } else {
    iconWidget = const SizedBox(width: iconAreaWidth);
  }

  if (isUser) {
    return Align(
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(child: messageWidget),
          const SizedBox(width: spacing),
          SizedBox(width: iconAreaWidth, child: iconWidget),
        ],
      ),
    );
  } else {
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: iconAreaWidth, child: iconWidget),
          const SizedBox(width: spacing),
          Flexible(child: messageWidget),
        ],
      ),
    );
  }
}
