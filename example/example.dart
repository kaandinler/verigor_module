import 'package:flutter/material.dart';
import 'package:verigor_module/verigor_module.dart';

void main() {
  // 1) Initialize the VerigorModule with a token provider.
  runApp(const MyApp());
}

//Example Token
String _getToken() {
  return '78a103c0-d081-708d-75b4-3269cac6fd2e:00964822-8834-4436-a860-44a29517d8db';
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Host App')),
        floatingActionButton: Builder(
          builder: (context) {
            // 2) Create a FloatingActionButton that opens the QAScreen
            // when pressed. The QAScreen will use the token provider to get the token.
            return FloatingActionButton(
              onPressed: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => QAScreen(tokenProvider: _getToken)));
              },
              child: const Icon(Icons.chat),
            );
          },
        ),
        body: const Center(child: Text('Tap the chat button')),
      ),
    );
  }
}
