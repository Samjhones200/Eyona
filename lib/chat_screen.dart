import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:flutter/material.dart';
import 'package:velocity_x/velocity_x.dart';

import 'chatmessage.dart';
import 'threedots.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  late OpenAI? chatGPT;
  bool _isImageSearch = false;
  bool _isTyping = false;

  @override
  void initState() {
    chatGPT = OpenAI.instance.build(
      token: "sk-cdab1d6d92ee4120a9fdde29875022bd", // ✅ DeepSeek API Key
      baseOption: HttpSetup(receiveTimeout: 60000),
      baseUrl: "https://api.deepseek.com/v1", // ✅ DeepSeek API Endpoint
    );
    super.initState();
  }

  @override
  void dispose() {
    chatGPT?.close();
    chatGPT?.genImgClose();
    super.dispose();
  }

  void _sendMessage() async {
    if (_controller.text.isEmpty) return;

    ChatMessage message = ChatMessage(
      text: _controller.text,
      sender: "user",
      isImage: false,
    );

    setState(() {
      _messages.insert(0, message);
      _isTyping = true;
    });

    _controller.clear();

    if (_isImageSearch) {
      final request = GenerateImage(message.text, 1, size: "256x256");
      final response = await chatGPT!.generateImage(request);
      insertNewData(response!.data!.last!.url!, isImage: true);
    } else {
      final request = CompleteText(
        prompt: message.text,
        model: "deepseek-chat", // ✅ Correct DeepSeek Model Name
        maxTokens: 200, // ✅ Prevents too-long responses
        temperature: 0.7, // ✅ Keeps responses balanced
      );

      final response = await chatGPT!.onCompleteText(request: request);
      insertNewData(response!.choices[0].text.trim(), isImage: false);
    }
  }

  void insertNewData(String response, {bool isImage = false}) {
    ChatMessage botMessage = ChatMessage(
      text: response,
      sender: "bot",
      isImage: isImage,
    );

    setState(() {
      _isTyping = false;
      _messages.insert(0, botMessage);
    });
  }

  Widget _buildTextComposer() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            onSubmitted: (value) => _sendMessage(),
            decoration: const InputDecoration.collapsed(
                hintText: "Ask something..."),
          ),
        ),
        ButtonBar(
          children: [
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: () {
                _isImageSearch = false;
                _sendMessage();
              },
            ),
            TextButton(
              onPressed: () {
                _isImageSearch = true;
                _sendMessage();
              },
              child: const Text("Generate Image"),
            )
          ],
        ),
      ],
    ).px16();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Chat with DeepSeek AI")),
      body: SafeArea(
        child: Column(
          children: [
            Flexible(
              child: ListView.builder(
                reverse: true,
                padding: Vx.m8,
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return _messages[index];
                },
              ),
            ),
            if (_isTyping) const ThreeDots(),
            const Divider(height: 1.0),
            Container(
              decoration: BoxDecoration(color: context.cardColor),
              child: _buildTextComposer(),
            )
          ],
        ),
      ),
    );
  }
}