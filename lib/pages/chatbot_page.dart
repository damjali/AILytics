import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  String? _fileContext;

  Future<void> _analyzeRecentFile() async {
    const url = "http://10.0.2.2:5000/analyze-file";
    //const url = "http://localhost:5000/analyze-file"; // For Windows
    //const url = "http://localhost:5000/analyze-file"; // iOS Simulator / Web
    //const url = "http://192.168.0.151:5000/analyze-file"; //Physical Device
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _fileContext = jsonEncode(data["file_summary"]);
        });
        _addMessage("Recent file analyzed. You can now ask questions based on its data.", false);
      } else {
        _addMessage("No recent file found.", false);
      }
    } catch (e) {
      _addMessage("Error analyzing file: $e", false);
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    _addMessage(text, true);
    const url = "http://10.0.2.2:5000/chat";
    //const url = "http://localhost:5000/chat"; // For Windows
    //const url = "http://localhost:5000/chat"; // iOS Simulator / Web
    //const url = "http://192.168.0.151:5000/chat"; //Physical Device

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"message": text, "file_context": _fileContext}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _addTypingMessage(data["response"]);
      } else {
        _addMessage("Error: ${response.body}", false);
      }
    } catch (e) {
      _addMessage("Failed to connect to chatbot API.", false);
    }
  }

  void _addMessage(String text, bool isUser) {
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: isUser));
    });
  }

  void _addTypingMessage(String fullText) async {
    String cleanedText = fullText.replaceAll("**", "");

    List<String> words = cleanedText.split(" ");
    String displayText = "";

    for (int i = 0; i < words.length; i++) {
      await Future.delayed(const Duration(milliseconds: 100)); // Adjust speed here
      setState(() {
        displayText += (i == 0 ? "" : " ") + words[i];
        if (_messages.isEmpty || _messages.last.isUser) {
          _messages.add(ChatMessage(text: displayText, isUser: false));
        } else {
          _messages[_messages.length - 1] = ChatMessage(text: displayText, isUser: false);
        }
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Assistant')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _messages[_messages.length - 1 - index];
              },
            ),
          ),
          const Divider(height: 1),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Ask me about your data...',
                      border: InputBorder.none,
                    ),
                    onSubmitted: (text) {
                      _controller.clear();
                      _sendMessage(text);
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.file_present),
                  onPressed: _analyzeRecentFile,
                  tooltip: 'Analyze Recent File',
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    final text = _controller.text;
                    _controller.clear();
                    _sendMessage(text);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;

  const ChatMessage({super.key, required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser)
            CircleAvatar(
              backgroundColor: Colors.blue,
              child: const Icon(Icons.smart_toy, color: Colors.white),
            ),
          Flexible(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser ? Colors.blue : Colors.grey[300],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                text,
                style: TextStyle(color: isUser ? Colors.white : Colors.black),
              ),
            ),
          ),
          if (isUser)
            CircleAvatar(
              backgroundColor: Colors.grey,
              child: const Icon(Icons.person, color: Colors.white),
            ),
        ],
      ),
    );
  }
}


