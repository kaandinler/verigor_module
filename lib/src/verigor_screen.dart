import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:verigor_module_flutter/models/message_type.dart';
import 'package:verigor_module_flutter/src/verigor_view_model.dart';
import 'package:verigor_module_flutter/src/widgets/example_question_widget.dart';

import 'widgets/resizable_answer_widget.dart';

class VeriGorModule extends StatefulWidget {
  final String Function() tokenProvider;
  final List<String>? exampleQuestions;
  VeriGorModule({super.key, required this.tokenProvider, List<String>? exampleQuestions})
      : exampleQuestions = exampleQuestions != null
            ? exampleQuestions.take(3).toList() // Maksimum 3 soru al
            : [];

  @override
  createState() => _VeriGorModuleState();
}

class _VeriGorModuleState extends State<VeriGorModule> with SingleTickerProviderStateMixin {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;
  String _threadId = 'threadId';
  String _selectedFile = "";
  bool _showFileList = false;
  int? _selectedExampleIndex;
  bool _showTabSection = false;

  late TabController _tabController;
  final VeriGorViewModel _viewModel = VeriGorViewModel();

  // Mesaj listesi: sorular da cevaplar da Message tipinde tutuluyor
  final List<Message> _messages = [];
  // Fetches the list of files from the server
  Future<List<String>> _getFiles() async {
    try {
      final token = widget.tokenProvider();
      return await _viewModel.getFiles(token);
    } catch (e) {
      // Hata durumunda boş liste döndür
      return [];
    }
  }

  void _sendQuestion() async {
    if (_textController.text.trim().isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
      _showFileList = false;
      _messages.add(Message.text(_textController.text.trim()));
    });
    final question = _textController.text.trim();
    _textController.clear();

    try {
      final msg = await _viewModel.sendQuestion(
        token: widget.tokenProvider(),
        question: question,
        threadId: _threadId,
        fileName: _selectedFile,
      );
      setState(() {
        _messages.add(msg);
      });

      await _saveChatHistory();

      if (mounted) {
        FocusScope.of(context).unfocus();
      }

      Future.delayed(const Duration(milliseconds: 800), () {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
          }
        });
      });

      _showTabSection = false;
    } catch (e) {
      setState(() {
        if (mounted) {
          _messages.add(Message.text('Mesaj gönderilirken hata oluştu: $e'));
        }
      });
    } finally {
      setState(() {
        if (mounted) {
          _isSending = false;
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadChatHistory();
  }

  Future<void> _saveChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final messagesJson = _messages
        .map((msg) => {
              'type': msg.type.toString(),
              'text': msg.text,
              'requestId': msg.requestId,
            })
        .toList();

    await prefs.setString('verigor_chat_messages', jsonEncode(messagesJson));
    await prefs.setString('verigor_thread_id', _threadId);
    await prefs.setString('verigor_selected_file', _selectedFile);
  }

  // Chat geçmişini yükle
  Future<void> _loadChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final messagesString = prefs.getString('verigor_chat_messages');
    final threadId = prefs.getString('verigor_thread_id');
    final selectedFile = prefs.getString('verigor_selected_file');

    if (messagesString != null && threadId != null) {
      final messagesList = jsonDecode(messagesString) as List;
      setState(() {
        _threadId = threadId;
        _selectedFile = selectedFile ?? '';
        _messages.clear();
        for (var msgData in messagesList) {
          if (msgData['type'].contains('text')) {
            _messages.add(Message.text(msgData['text']));
          } else {
            _messages.add(Message.webView(msgData['requestId']));
          }
        }
      });
    } else {
      // İlk açılışsa yeni thread oluştur
      _threadId = Uuid().v4();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _startNewChat() {
    setState(() {
      _messages.clear();
      _threadId = Uuid().v4();
      _selectedFile = "";
      _textController.clear();
      _showTabSection = false;
      _showFileList = false;
      _selectedExampleIndex = null;
    });
    _clearChatHistory();
  }

  Future<void> _clearChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('verigor_chat_messages');
    await prefs.remove('verigor_thread_id');
    await prefs.remove('verigor_selected_file');
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
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          actions: [
            TextButton.icon(
              onPressed: _startNewChat,
              icon: Icon(Icons.add, color: Colors.blue),
              label: Text(
                'Yeni Sohbet',
                style: TextStyle(color: Colors.blue),
              ),
            ),
            SizedBox(width: 8),
          ],
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(children: [
            _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Center(
                          child: Image.asset(
                            'assets/images/verigor_guy.png', // Robot resminiz
                            package: 'verigor_module_flutter',
                            width: 140,
                            height: 140,
                            errorBuilder: (context, error, stackTrace) {
                              // Yedek bir ikon göster
                              return Icon(Icons.smart_toy, size: 75, color: Colors.white);
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Başlık
                        Text(
                          'Size Nasıl Yardımcı Olabilirim?',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Alt başlık
                        Text(
                          'Merak ettiğiniz herhangi bir soruyu bana sorabilirsiniz.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
            _answerWebViewWidgets(),
            const SizedBox(height: 200)
          ]),
        ),
        bottomSheet: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1) Sekme başlıkları ve yanındaki aç/kapa butonu
            Row(
              children: [
                Expanded(
                  child: TabBar(
                    controller: _tabController,
                    labelColor: Colors.blue,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Colors.blue,
                    tabs: const [
                      Tab(text: 'Dosyalar'),
                      Tab(text: 'Örnek Sorular'),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(_showTabSection ? Icons.expand_less : Icons.expand_more),
                  onPressed: () => setState(() => _showTabSection = !_showTabSection),
                ),
              ],
            ),

            // 2) Animasyonlu açılır-kapanır içerik
            ClipRect(
              child: AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: _showTabSection ? 250 : 0),
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _fileListWidget(),
                      ExampleQuestionsWidget(
                        questions: widget.exampleQuestions ?? [],
                        selectedIndex: _selectedExampleIndex,
                        onChanged: (v) => setState(() {
                          if (v != null) {
                            _textController.text = v;
                          }
                        }),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 3) Gönderme alanı vs.
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
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: ResizableAnswerWidget(requestId: msg.requestId ?? '', tokenProvider: widget.tokenProvider),
          );
        }
      },
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
          if (snap.connectionState == ConnectionState.waiting) {
            return const Padding(padding: EdgeInsets.all(8), child: Center(child: CircularProgressIndicator()));
          }

          if (snap.hasError) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red[300]),
                const SizedBox(width: 8),
                Flexible(child: Text('Dosyalar yüklenirken bir hata oluştu. Lütfen tekrar deneyin.')),
              ],
            );
          }

          final files = snap.data ?? [];

          if (files.isEmpty) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, color: Colors.blue[100]),
                const SizedBox(width: 8),
                Text('Dosya bulunamadı'),
              ],
            );
          }

          return ListView(
            shrinkWrap: true,
            children: files.map((name) {
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
                  maxLength: 100,
                  controller: _textController,
                  decoration: InputDecoration(
                    hintText: 'Sorunuzu buraya yazabilirsiniz',
                    border: const OutlineInputBorder(),
                    counterText: '', // Karakter sayacını gizler
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
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
                  : DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        color: Colors.white,
                        icon: const Icon(Icons.send),
                        onPressed: _sendQuestion,
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
