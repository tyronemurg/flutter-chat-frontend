import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chatbot App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  TextEditingController _messageController = TextEditingController();
  List<String> _chats = [];
  List<String> _mainChats = []; // List for the main chat area
  String _selectedChat = "";

  void _sendMessage() async {
    String message = _messageController.text;
    _messageController.clear();

    // Add the user's message to the main chat area
    setState(() {
      _mainChats.insert(0,
          message); // Insert at the beginning to show the latest message first
    });

    // Make API call to backend
    final response = await http.post(
      Uri.parse('http://localhost:5000/send_message'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'message': message,
      }),
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> responseData = jsonDecode(response.body);
      String chatbotResponse = responseData['message'];

      // Add the chatbot's response to the main chat area
      setState(() {
        _mainChats.insert(
            0,
            _extractContent(
                chatbotResponse)); // Insert at the beginning to show the latest message first
      });
    } else {
      throw Exception('Failed to send message');
    }
  }

  // Function to extract content from ChatCompletionMessage
  String _extractContent(String message) {
    final RegExp regex = RegExp(r"content='(.*?)'");
    final match = regex.firstMatch(message);
    if (match != null && match.groupCount >= 1) {
      return match.group(1) ?? message;
    } else {
      return message;
    }
  }

  void _getChats() async {
    final response =
        await http.get(Uri.parse('http://localhost:5000/get_chats'));

    if (response.statusCode == 200) {
      Map<String, dynamic> responseData = jsonDecode(response.body);
      List<dynamic> chats = responseData['chats'];
      setState(() {
        _chats = List<String>.from(chats.map((chat) {
          if (chat is String) {
            return chat;
          } else if (chat is Map<String, dynamic> &&
              chat.containsKey('message')) {
            return _extractContent(chat['message']);
          } else {
            return chat.toString();
          }
        }));
      });
    } else {
      throw Exception('Failed to load chats');
    }
  }

  void _selectChat(String chat) {
    setState(() {
      _selectedChat = chat;
    });
  }

  @override
  void initState() {
    super.initState();
    _getChats();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chatbot'),
      ),
      body: Row(
        children: [
          // Sidebar for recent chat history
          Container(
            width: 200,
            child: ListView.builder(
              itemCount: _chats.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  title: Text(_chats[index]),
                  onTap: () {
                    _selectChat(_chats[index]);
                  },
                );
              },
            ),
          ),
          Expanded(
            child: Column(
              children: [
                // Main area for displaying selected chat and current message
                Expanded(
                  child: Container(
                    alignment: Alignment.topLeft,
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Display current message sent by the user
                        Text(
                          _mainChats.isNotEmpty
                              ? _mainChats.first
                              : '', // Display the latest message
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        // Display selected chat
                        Text(_selectedChat),
                        SizedBox(height: 8),
                        // Display previous chat history
                        for (var chat
                            in _mainChats.skip(1)) // Skip the latest message
                          Text(chat),
                      ],
                    ),
                  ),
                ),
                // Input field for sending messages
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: 'Enter your message',
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.send),
                        onPressed: _sendMessage,
                      ),
                    ],
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
