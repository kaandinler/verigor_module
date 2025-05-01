import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:verigor_module/data/service/file_service.dart';
import 'package:verigor_module/data/service/query_service.dart';
import 'package:verigor_module/models/repository/file_repository.dart';
import 'package:verigor_module/models/repository/query_repository.dart';

import 'resizable_answer_widget.dart';

class QAScreen extends StatefulWidget {
  final String endpoint;
  final String Function() tokenProvider;
  const QAScreen({super.key, required this.endpoint, required this.tokenProvider});

  @override
  createState() => _QAScreenState();
}

class _QAScreenState extends State<QAScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;
  String _threadId = 'threadId';
  String _selectedFile = "";
  bool _showFileList = false;

  // Repositories for file and query services
  final QueryRepository _queryRepository = QueryRepository(service: QueryService());
  final FileRepository _fileRepository = FileRepository(service: FileService());

  // Mesaj listesi: sorular da cevaplar da Message tipinde tutuluyor
  final List<Message> _messages = [];

  // Fetches the list of files from the server
  Future<List<String>> _getFiles() async {
    final token = widget.tokenProvider();
    final response = await _fileRepository.getFiles(token);
    log('Files: $response');
    return response.map((file) => file.name).toList();
  }

  void _sendQuestion() async {
    if (_textController.text.trim().isEmpty || _isSending) return;
    if (_selectedFile.isEmpty) return;

    setState(() {
      _isSending = true;
      _showFileList = false;
      _messages.add(Message.text(_textController.text.trim()));
    });
    final question = _textController.text.trim();
    _textController.clear();

    try {
      // Here you could pass selectedFiles to your payloadBuilder if you like
      final query = question;
      final threadId = _threadId;
      final fileName = _selectedFile; // Use the selected file

      final entity = await _queryRepository.createQuery(xToken: widget.tokenProvider(), query: query, threadId: threadId, fileName: fileName);

      setState(() {
        _messages.add(Message.webView(entity.requestId));
      });

      // Hide keyboard
      if (mounted) {
        FocusScope.of(context).unfocus();
      }

      // scroll to bottom
      await Future.delayed(const Duration(milliseconds: 100));
      _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    } catch (e) {
      setState(() => _messages.add(Message.text('Hata: $e')));
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  void initState() {
    super.initState();
    // Generate UUID for threadId
    _threadId = Uuid().v4();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus(); // Hide the keyboard when tapping outside
        setState(() {
          _showFileList = false; // Hide the file list when tapping outside
        });
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade200,
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(children: [_answerWebViewWidgets(), const SizedBox(height: 200)]),
        ),
        bottomSheet: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            //Show - Hide File List Button
            _showHideFileList(),

            if (_showFileList) _fileListWidget(),
            _sendQuestionInputField(),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  ListView _answerWebViewWidgets() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      controller: _scrollController,
      itemCount: _messages.length,
      itemBuilder: (_, i) {
        final msg = _messages[i];
        if (msg.type == MessageType.text) {
          // Soruyu sağa hizalı balon olarak göster
          return Align(
            alignment: Alignment.centerRight,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.blue.shade100, borderRadius: BorderRadius.circular(8)),
              child: Text(msg.text!),
            ),
          );
        } else {
          // Cevabı ResizableWebView ile göster
          // final url = 'https://d2ql5i2hsdk9xi.cloudfront.net/public/result?request-id=${msg.requestId}';
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: ResizableAnswerWidget(requestId: msg.requestId ?? '', tokenProvider: widget.tokenProvider),
          );
        }
      },
    );
  }

  Padding _showHideFileList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _selectedFile == "" ? 'Lütfen bir dosya seçin' : 'Seçilen Dosya "$_selectedFile" ',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
          ),
          IconButton(
            icon: Icon(_showFileList ? Icons.keyboard_arrow_down_outlined : Icons.keyboard_arrow_up_outlined),
            onPressed: () {
              setState(() {
                _showFileList = !_showFileList;
              });
            },
          ),
        ],
      ),
    );
  }

  Container _fileListWidget() {
    return Container(
      constraints: BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        border: Border.all(width: 2, style: BorderStyle.solid, color: Colors.grey.shade300),
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),

      child: FutureBuilder<List<String>>(
        future: _getFiles(),
        builder: (context, snap) {
          if (!snap.hasData) return const Padding(padding: EdgeInsets.all(8), child: Center(child: CircularProgressIndicator()));
          final files = snap.data!;
          return ListView(
            shrinkWrap: true,
            children:
                files.map((name) {
                  return RadioListTile(
                    groupValue: _selectedFile,
                    title: Text(name),
                    value: name,
                    onChanged: (value) {
                      setState(() {
                        _selectedFile = value!;
                      });
                    },
                  );
                }).toList(),
          );
        },
      ),
    );
  }

  SafeArea _sendQuestionInputField() {
    return SafeArea(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(width: 2, style: BorderStyle.solid, color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  decoration: const InputDecoration(hintText: 'Sorunuzu buraya yazabilirsiniz', border: OutlineInputBorder()),
                  // onTap:
                  //     () => setState(() {
                  //       _showFileList = true;
                  //     }),
                  onSubmitted: (_) {
                    _sendQuestion();
                    setState(() {
                      _showFileList = false;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              _isSending
                  ? const SizedBox(width: 32, height: 32, child: CircularProgressIndicator(strokeWidth: 2))
                  : IconButton(icon: const Icon(Icons.send), onPressed: _sendQuestion),
            ],
          ),
        ),
      ),
    );
  }
}

/// Defines the type of message: either a text question or a webview answer.
enum MessageType { text, webview }

class Message {
  final MessageType type;
  final String? text;
  final String? requestId;

  Message._(this.type, {this.text, this.requestId});
  factory Message.text(String txt) => Message._(MessageType.text, text: txt);
  factory Message.webView(String reqId) => Message._(MessageType.webview, requestId: reqId);
}
