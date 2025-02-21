// ignore_for_file: invalid_use_of_protected_member

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

Future<void> pickImageHelper({
  required State state,
  required ImageSource source,
  required Future<void> Function(XFile image) sendImageToServer,
  required List<Map<String, dynamic>> messages,
  required void Function(bool) updateLoading,
  required List<Map<String, String>> history,
}) async {
  final ImagePicker picker = ImagePicker();
  final XFile? image = await picker.pickImage(source: source);

  if (image != null) {
    state.setState(() {
      updateLoading(true);
      messages.add({
        "type": "image",
        "imagePath": image.path,
        "sender": "user",
      });
      history.add({"role": "user", "content": "[Image Sent]"});
    });

    await sendImageToServer(image);
    state.setState(() {
      updateLoading(false);
    });
  }
}
