import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:verigor_module_flutter/models/message_type.dart';
import 'package:verigor_module_flutter/src/verigor_view_model.dart';
import 'package:verigor_module_flutter/src/widgets/example_question_widget.dart';

import 'widgets/resizable_answer_widget.dart';

class VeriGorModule extends StatefulWidget {
  final String Function() tokenProvider;
  final List<String>? exampleQuestions;
  VeriGorModule({super.key, required this.tokenProvider, List<String>? exampleQuestions})
      : exampleQuestions = exampleQuestions ?? List.filled(3, '', growable: false);

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

  final List<String> _defaultExampleQuestions = [
    '“Merhaba, nasılsın?”',
    '“Bugünkü hava nasıl?”',
    '“Flutter’da state nasıl yönetilir?”',
  ];

  late TabController _tabController;
  final VeriGorViewModel _viewModel = VeriGorViewModel();

  // Mesaj listesi: sorular da cevaplar da Message tipinde tutuluyor
  final List<Message> _messages = [];

  // Fetches the list of files from the server
  Future<List<String>> _getFiles() async {
    final token = widget.tokenProvider();
    return await _viewModel.getFiles(token);
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
    // Generate UUID for threadId
    _threadId = Uuid().v4();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
                        questions: widget.exampleQuestions ?? _defaultExampleQuestions,
                        selectedIndex: _selectedExampleIndex,
                        onChanged: (v) => setState(() => _textController.text = widget.exampleQuestions?[v ?? 0] ?? ""),
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
          if (!snap.hasData) return const Padding(padding: EdgeInsets.all(8), child: Center(child: CircularProgressIndicator()));
          final files = snap.data!;

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
                  controller: _textController,
                  decoration: const InputDecoration(hintText: 'Sorunuzu buraya yazabilirsiniz', border: OutlineInputBorder()),
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
