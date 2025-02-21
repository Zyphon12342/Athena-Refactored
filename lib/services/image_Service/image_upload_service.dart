// ignore_for_file: invalid_use_of_protected_member

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
// ignore: unnecessary_import
import 'package:image_picker/image_picker.dart';

Future<void> sendImageToServerHelper({
  required State state,
  required XFile imageFile,
  required List<Map<String, dynamic>> messages,
  // You can override the URL if needed.
  String uploadUrl = 'https://just-mainly-monster.ngrok-free.app/',
}) async {
  File file = File(imageFile.path);

  // Compress the image.
  final tempDir = await getTemporaryDirectory();
  final targetPath = path.join(
    tempDir.absolute.path,
    "temp_${DateTime.now().millisecondsSinceEpoch}.jpg",
  );
  XFile? compressedFile = await FlutterImageCompress.compressAndGetFile(
    file.absolute.path,
    targetPath,
    quality: 80,
  );
  if (compressedFile == null) {
    state.setState(() {
      messages.add({
        "type": "text",
        "text": "Failed to compress image.",
        "sender": "bot",
      });
    });
    return;
  }

  // Encode the compressed image to Base64.
  final bytes = await compressedFile.readAsBytes();
  String base64Image = base64Encode(bytes);
  String fileName = path.basename(compressedFile.path);

  // Prepare JSON payload.
  final body = jsonEncode({
    "image": base64Image,
    "name": fileName,
  });

  var url = Uri.parse(uploadUrl);
  try {
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: body,
    );
    if (response.statusCode == 200) {
      state.setState(() {
        messages.add({
          "type": "text",
          "text": "Image uploaded successfully!",
          "sender": "bot",
        });
      });
    } else {
      state.setState(() {
        messages.add({
          "type": "text",
          "text": "Failed to upload image. Status: ${response.statusCode}",
          "sender": "bot",
        });
      });
    }
  } catch (e) {
    state.setState(() {
      messages.add({
        "type": "text",
        "text": "Error during image upload: $e",
        "sender": "bot",
      });
    });
  }
}
