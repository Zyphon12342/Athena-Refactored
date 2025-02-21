import 'package:flutter/material.dart';

class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onClear;

  const ChatAppBar({super.key, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(50),
        ),
        child: const Text(
          "ATHENA",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: "nasa",
            color: Colors.purpleAccent,
            letterSpacing: 5,
            fontSize: 30,
          ),
        ),
      ),
      centerTitle: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.replay_rounded, color: Colors.grey),
        onPressed: onClear,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
