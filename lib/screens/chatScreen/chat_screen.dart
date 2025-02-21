// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

// Import your services.
import '../../services/chat/chat_service.dart';
import '../../services/image_Service/image_upload_service.dart';
import '../../services/image_Service/image_picker_helper.dart';
import '../../services/chat/message_processor.dart';

// Import your custom widgets.
import '../../widgets/chats/chat_appbar.dart';
import '../../widgets/chats/chat_list.dart';
import '../../widgets/chats/chat_input.dart';

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
      appBar: ChatAppBar(
        onClear: () {
          setState(() {
            messages.clear();
            history.clear();
          });
        },
      ),
      body: Column(
        children: [
          Expanded(
            child: ChatList(
              messages: messages,
              scrollController: _scrollController,
              maxBubbleWidth: maxBubbleWidth,
            ),
          ),
          ChatInput(
            controller: _controller,
            focusNode: _focusNode,
            isLoading: _isLoading,
            onSend: _sendMessage,
            onCancel: _cancelMessage,
            onImagePick: () => _pickImage(ImageSource.gallery),
          ),
        ],
      ),
    );
  }
}
