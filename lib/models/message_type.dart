/// Defines the type of message: either a text question or a webview answer.
enum MessageType { text, webview }

class Message {
  final MessageType type;
  final String? text;
  final String? requestId;

  Message._(this.type, {this.text, this.requestId});
  factory Message.text(String txt) => Message._(MessageType.text, text: txt);
  factory Message.webView(String reqId) => Message._(MessageType.webview, requestId: reqId);

  bool get isText => type == MessageType.text;
  bool get isWebView => type == MessageType.webview;
  String get textValue => text ?? '';
  String get requestIdValue => requestId ?? '';
}
