// ignore_for_file: library_private_types_in_public_api

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';

// Import services.
import '../../services/chat/chat_service.dart';
import '../../services/image_Service/image_upload_service.dart';
import '../../services/image_Service/image_picker_helper.dart';
import '../../services/chat/message_processor.dart';

// Import widgets.
import '../../widgets/messages/message_bubble.dart';

// Global chat history.
List<Map<String, String>> history = [];

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> messages = [];
  bool _isLoading = false;
  final ChatService _chatService = ChatService();

  Future<void> _sendMessage() async {
    if (_controller.text.isEmpty) return;
    final inputText = _controller.text.trim();

    // Process clear command.
    if (inputText == "clear()") {
      setState(() {
        messages.clear();
      });
      _controller.clear();
      return;
    }

    // Add user message.
    setState(() {
      _isLoading = true;
      messages.add({
        "type": "text",
        "text": inputText,
        "sender": "user",
      });
      history.add({"role": "user", "content": inputText});
    });

    // Add a loading indicator.
    final int loadingMessageIndex = messages.length;
    setState(() {
      messages.add({
        "type": "loading",
        "sender": "bot",
      });
    });

    // Send the message.
    final response = await _chatService.sendString(inputText, history);
    history.add({"role": "assistant", "content": response.toString()});

    // Remove the loading indicator.
    setState(() {
      messages.removeAt(loadingMessageIndex);
    });

    // Process the server response.
    setState(() {
      processServerResponse(response: response, messages: messages);
      _isLoading = false;
    });

    _controller.clear();
    _focusNode.requestFocus();

    // Scroll to bottom.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _cancelMessage() {
    _chatService.cancelRequest();
    setState(() {
      _isLoading = false;
      if (messages.isNotEmpty && messages.last["type"] == "loading") {
        messages.removeLast();
      }
      if (messages.isNotEmpty && messages.last["sender"] == "user") {
        messages.removeLast();
      }
    });
  }

  Future<void> _sendImageToServer(XFile imageFile) async {
    await sendImageToServerHelper(
      state: this,
      imageFile: imageFile,
      messages: messages,
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    await pickImageHelper(
      state: this,
      source: source,
      sendImageToServer: _sendImageToServer,
      messages: messages,
      updateLoading: (value) => _isLoading = value,
      history: history,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _chatService.cancelRequest();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxBubbleWidth = MediaQuery.of(context).size.width * 0.7;

    return Scaffold(
      appBar: AppBar(
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
          onPressed: () {
            setState(() {
              messages.clear();
              history.clear();
            });
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(10),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final String sender = msg["sender"] ?? "bot";
                final bool isUser = sender == "user";

                switch (msg["type"]) {
                  case "text":
                    final bubble = ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxBubbleWidth),
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color:
                              isUser ? Colors.purpleAccent : Colors.grey[800],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          msg["text"].toString(),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 20),
                        ),
                      ),
                    ).animate().fade(duration: 300.ms).slideX(
                          begin: isUser ? 1 : -1,
                        );
                    return buildMessageWithIcon(
                      messageWidget: bubble,
                      index: index,
                      messages: messages,
                      isUser: isUser,
                    );
                  case "image":
                    final imageWidget = ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: maxBubbleWidth,
                        maxHeight: 250,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(File(msg["imagePath"]),
                            fit: BoxFit.cover),
                      ),
                    );
                    return buildMessageWithIcon(
                      messageWidget: imageWidget,
                      index: index,
                      messages: messages,
                      isUser: isUser,
                    );
                  case "loading":
                    final bubble = ConstrainedBox(
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
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ).animate().fade(duration: 300.ms).slideX(
                          begin: isUser ? 1 : -1,
                        );
                    return buildMessageWithIcon(
                      messageWidget: bubble,
                      index: index,
                      messages: messages,
                      isUser: isUser,
                    );
                  // For card types (bus, airplane, etc.) simply pass the widget.
                  case "bus":
                  case "airplane":
                  case "amazon":
                  case "airbnb":
                  case "booking":
                  case "restaurant":
                  case "fashion":
                  case "movieslist":
                  case "mtime":
                  case "perplexity":
                  case "uber":
                    return buildMessageWithIcon(
                      messageWidget: msg["data"],
                      index: index,
                      messages: messages,
                      isUser: isUser,
                    );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SizedBox(
                  height: 56,
                  width: 56,
                  child: FloatingActionButton(
                    backgroundColor: Colors.grey[900],
                    onPressed: () => _pickImage(ImageSource.gallery),
                    child: const Icon(Icons.photo, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    enabled: !_isLoading,
                    style: const TextStyle(color: Colors.white),
                    onSubmitted: (_) => _sendMessage(),
                    textInputAction: TextInputAction.send,
                    maxLines: null,
                    decoration: InputDecoration(
                      hintText: "Ask something...",
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: _isLoading ? Colors.grey : Colors.grey[900],
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
                    backgroundColor:
                        _isLoading ? Colors.red : Colors.purpleAccent,
                    onPressed: _isLoading ? _cancelMessage : _sendMessage,
                    child: Icon(
                      _isLoading ? Icons.stop : Icons.send,
                      size: 24,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
