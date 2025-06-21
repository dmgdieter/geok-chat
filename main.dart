import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(const GEOKApp());
}

class GEOKApp extends StatelessWidget {
  const GEOKApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatModel(),
      child: MaterialApp(
        title: 'GEOK Chat',
        theme: ThemeData(
          primarySwatch: Colors.indigo,
          useMaterial3: true,
        ),
        home: const ChatPage(),
      ),
    );
  }
}

class ChatModel extends ChangeNotifier {
  final List<Message> _messages = [];
  bool _loading = false;

  List<Message> get messages => List.unmodifiable(_messages);
  bool get loading => _loading;

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;
    _messages.add(Message(role: 'user', content: content));
    _loading = true;
    notifyListeners();

    try {
      // TODO: Replace with your own backend or OpenAI proxy endpoint.
      // This is a demo hitting fetch.sh or any simple passthrough server.
      const endpoint = 'https://api.openai.com/v1/chat/completions';
      const apiKey = 'YOUR_OPENAI_KEY_HERE';

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': _messages.map((m) => m.toJson()).toList(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final assistantReply =
            data['choices'][0]['message']['content'] as String? ?? '';
        _messages.add(Message(role: 'assistant', content: assistantReply));
      } else {
        _messages.add(Message(
            role: 'assistant',
            content: 'Error: ${response.statusCode}\n${response.body}'));
      }
    } catch (e) {
      _messages.add(
          Message(role: 'assistant', content: 'Error contacting server: $e'));
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}

class Message {
  final String role;
  final String content;

  Message({required this.role, required this.content});

  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('GEOK Chat')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: chat.messages.length,
              itemBuilder: (context, index) {
                final msg = chat.messages[index];
                final isUser = msg.role == 'user';
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser
                          ? Colors.indigo.shade200
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(msg.content),
                  ),
                );
              },
            ),
          ),
          if (chat.loading) const LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: (_) => _onSend(chat),
                    decoration:
                        const InputDecoration(hintText: 'Schreib etwas...'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: chat.loading ? null : () => _onSend(chat),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onSend(ChatModel chat) {
    final text = _controller.text;
    _controller.clear();
    chat.sendMessage(text);
  }
}
