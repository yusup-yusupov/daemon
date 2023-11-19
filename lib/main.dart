import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(ChatApp());

class ChatApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daemon',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        colorScheme: ColorScheme.fromSwatch().copyWith(secondary: Colors.blue),
        scaffoldBackgroundColor:
            Colors.grey[10], // Set the background color here
      ),
      home: ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  @override
  State createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  final List<Widget> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSending = false;

  void _handleSubmitted(String text) async {
    _textController.clear();
    // Insert user message first
    setState(() {
      _messages.insert(0, _buildMessage(text, true)); // true for user message
      _isSending = true;
      _messages.insert(0, _buildLoadingIndicator());
    });
    _focusNode.requestFocus();

    try {
      // Send API request
      var response = await http.post(
        Uri.parse(
            'https://daemon-dialoguers-27ad56ecc960.herokuapp.com/api/get-answer'), // Replace with actual IP if testing on device
        headers: {"Content-Type": "application/json"},
        body: json.encode({'message': text}),
      );

      if (response.statusCode == 200) {
        final String answer = json.decode(response.body)['answer'];
        setState(() {
          _isSending = false;
          _messages.removeAt(0); // Remove loading indicator
          _messages.insert(
              0, _buildMessage(answer, false)); // Insert server response
        });
      } else {
        debugPrint('Failed with status code: ${response.statusCode}');
        setState(() {
          _isSending = false;
          //_messages.removeAt(0); // Remove loading indicator
        });
      }
    } catch (e) {
      debugPrint('Error making request: $e');
      setState(() {
        _isSending = false;
        //_messages.removeAt(0); // Remove loading indicator
      });
    }
  }

  Widget _buildTextComposer() {
    return Padding(
      padding: const EdgeInsets.only(
          left: 15.0,
          right: 15.0,
          bottom: 40.0,
          top: 10.0), // Add bottom padding
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.0), // Rounded corners
          border: Border.all(color: Colors.grey), // Border color
          color: Colors.white, // Background color of the text field
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: EdgeInsets.only(left: 20.0), // Reduced left padding
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                      20.0), // Match container's border radius
                  color: Colors.white, // Background color of the text field
                ),
                child: TextField(
                  controller: _textController,
                  focusNode: _focusNode,
                  decoration: const InputDecoration(
                    hintText: "Send a message",
                    border: InputBorder.none,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 10.0,
                        vertical: 6.0), // Adjusted internal padding
                  ),
                  maxLines: null, // Allows for unlimited lines
                  keyboardType: TextInputType.multiline,
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: IconButton(
                icon: const Icon(Icons.send),
                onPressed: _isSending
                    ? null
                    : () => _handleSubmitted(_textController.text),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage(String message, bool isUserMessage) {
    return Align(
      alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.66),
        margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
        padding: EdgeInsets.all(10.0),
        decoration: BoxDecoration(
          color: isUserMessage ? Colors.blue : Colors.grey[300],
          borderRadius: BorderRadius.circular(15.0),
        ),
        child: Text(
          message,
          style: TextStyle(color: isUserMessage ? Colors.white : Colors.black),
          softWrap: true,
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.66),
        margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
        padding: EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            CircularProgressIndicator(),
            SizedBox(width: 10),
            Text('Waiting for response...'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _focusNode.unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor:
              Colors.white, // Set the navigation bar background color
          title: const Text(
            "Daemon Chat",
            style: TextStyle(
              color: Colors.black87, // Set the font color
              fontWeight: FontWeight.w400, // Set the font weight
            ),
          ),
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.black,
            ),
            onPressed: () {
              // Add your code to navigate back or comment it out as needed
              // Navigator.pop(context);
            },
          ),
        ),
        body: Column(
          children: [
            Flexible(
              child: ListView.builder(
                padding: const EdgeInsets.all(8.0),
                reverse: true,
                itemBuilder: (_, int index) => _messages[index],
                itemCount: _messages.length,
              ),
            ),
            const Divider(height: 1.0),
            Container(
              decoration: BoxDecoration(color: Theme.of(context).cardColor),
              child: _buildTextComposer(),
            ),
          ],
        ),
      ),
    );
  }
}
