import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class ResizableAnswerWidget extends StatefulWidget {
  final String requestId;
  final String Function() tokenProvider;
  const ResizableAnswerWidget({super.key, required this.requestId, required this.tokenProvider});

  @override
  createState() => _ResizableAnswerWidgetState();
}

class _ResizableAnswerWidgetState extends State<ResizableAnswerWidget> {
  double _height = 200; // başlangıç yüksekliği

  late final _answerUrl = "https://d2ql5i2hsdk9xi.cloudfront.net/public/result?request-id=${widget.requestId}";
  @override
  Widget build(BuildContext context) {
    return Container(
      // Dinamik yükseklik
      height: _height,
      // Kenarlık/marjin ekleyebilirsiniz
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8)),
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus(); // Klavyeyi kapat
        },
        child: _webView(context),
      ),
    );
  }

  InAppWebView _webView(BuildContext context) {
    return InAppWebView(
      // 1) Header’lı ilk istek
      initialUrlRequest: URLRequest(
        url: WebUri(_answerUrl),
        // headers: {'x-token': widget.tokenProvider()},
      ),
      //
      // initialUrlRequest: URLRequest(url: WebUri(_answer_url), headers: {"Authorization": "Bearer $token"}),
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,

        // disableHorizontalScroll: false,
        // disableVerticalScroll: true,
      ),
      // onLoadStop: (controller, __) async {
      //   // after initial “loading” screen, do the real fetch:
      //   final token = widget.tokenProvider();
      //   final resp = await Dio().get<String>(
      //     _answerUrl,
      //     options: Options(headers: {'x-token': token}),
      //   );
      //   // push the HTML into the WebView:
      //   await controller.loadData(data: resp.data!, baseUrl: WebUri(_answerUrl));
      //   // measure height:
      //   final raw = await controller.evaluateJavascript(source: 'document.documentElement.scrollHeight;');
      //   if (raw is num) setState(() => _height = raw.toDouble());
      // },
      onWebViewCreated: (controller) async {
        controller.addJavaScriptHandler(
          handlerName: 'NotifyFetchResult',
          callback: (args) {
            final url = args.isNotEmpty ? args[0] as String : '';
            final status = args.length > 1 ? args[1] as int : -1;

            // 403 yakalama
            if (status == 403) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Authentication failed (403). Lütfen tekrar giriş yapın.')));
              controller.stopLoading();
              controller.loadUrl(urlRequest: URLRequest(url: WebUri('about:blank')));
              return;
            }

            // Belirli endpoint tamamlandığında yükseklik ölçümünü tetikle
            if (url.contains('/api/query') || url.contains('/public/result')) {
              controller.evaluateJavascript(
                source: """
                          window.flutter_inappwebview.callHandler(
                            'SetContentHeight',
                            document.body.scrollHeight
                          );
                        """,
              );
            }
          },
        );

        await controller.addUserScript(
          userScript: UserScript(
            injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
            forMainFrameOnly: true,
            source: r"""
              (function() {
                // --- FETCH OVERRIDE ---
                const origFetch = window.fetch;
                window.fetch = function(input, init = {}) {
                  const url = typeof input === 'string' ? input : input.url;
                  return origFetch(input, init).then(response => {
                    const status = response.status;
                    response.clone().text().then(body => {
                      window.flutter_inappwebview.callHandler(
                        'NotifyFetchResult', url, status, body
                      );
                    });
                    return response;
                  }, err => {
                    // Ağ hatası
                    window.flutter_inappwebview.callHandler(
                      'NotifyFetchResult', url, err.status || -1, ''
                    );
                    return Promise.reject(err);
                  });
                };

                // --- XHR OVERRIDE ---
                (function() {
                  const XHR = XMLHttpRequest.prototype;
                  const origOpen = XHR.open;
                  const origSend = XHR.send;
                  XHR.open = function(method, url) {
                    this._reqUrl = url;
                    return origOpen.apply(this, arguments);
                  };
                  XHR.send = function(body) {
                    this.addEventListener('load', () => {
                      window.flutter_inappwebview.callHandler(
                        'NotifyFetchResult', this._reqUrl, this.status, this.responseText
                      );
                    });
                    this.addEventListener('error', () => {
                      window.flutter_inappwebview.callHandler(
                        'NotifyFetchResult', this._reqUrl, this.status || -1, ''
                      );
                    });
                    return origSend.apply(this, arguments);
                  };
                })();

                // --- AXIOS OVERRIDE ---
                if (window.axios && window.axios.interceptors) {
                  // Başarılı cevap
                  window.axios.interceptors.response.use(function(response) {
                    const url = response.config.url || '';
                    const status = response.status;
                    const data = JSON.stringify(response.data);
                    window.flutter_inappwebview.callHandler(
                      'NotifyFetchResult', url, status, data
                    );
                    return response;
                  }, function(error) {
                    // Hata cevap veya ağ hatası
                    const resp = error.response || {};
                    const url = resp.config?.url || error.config?.url || '';
                    const status = resp.status || -1;
                    const data = resp.data ? JSON.stringify(resp.data) : '';
                    window.flutter_inappwebview.callHandler(
                      'NotifyFetchResult', url, status, data
                    );
                    return Promise.reject(error);
                  });
                }
              })();
      """,
          ),
        );

        // final token = widget.headers?['Authorization'] ?? widget.tokenProvider();
        final bearer = 'Bearer ';
        // final bearer = 'Bearer $token';
        final script = '''
                    (function () {
                      const TOKEN = "${bearer.replaceAll('"', r'\"')}";
                      const XHR = XMLHttpRequest.prototype;
                      /* ----------------------------------------------------------
                        FETCH
                      ---------------------------------------------------------- */
                      const origFetch = window.fetch;
                      window.fetch = function (input, init = {}) {
                        init.headers = new Headers(init.headers || {});

                        init.headers.set('x-token', '${widget.tokenProvider()}');
                        return origFetch.call(this, input, init);
                      };
                      /* ----------------------------------------------------------
                        XHR – open  +  setRequestHeader
                      ---------------------------------------------------------- */
                      const origOpen  = XHR.open;
                      const origSetRH = XHR.setRequestHeader;
                      XHR.open = function () {
                        // her istekte doğru header olsun diye işaret koy
                        this._forceAuth = true;
                        return origOpen.apply(this, arguments);
                      };
                      XHR.setRequestHeader = function (name, value) {
                        if (name.toLowerCase() === 'authorization') {
                          // sayfanın 'undefined' değerini YOK SAY
                          return;                    // hiçbir şey ekleme
                        }
                        return origSetRH.apply(this, arguments);
                      };
                      const origSend = XHR.send;
                      XHR.send = function () {
                        if (this._forceAuth) {
                          try {
                            origSetRH.call(this, 'x-token', '${widget.tokenProvider()}');
                          } catch (e) {}
                        }
                        return origSend.apply(this, arguments);
                      };
                    })();
                  ''';

        await controller.addUserScript(
          userScript: UserScript(source: script, injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START, forMainFrameOnly: false),
        );

        controller.addJavaScriptHandler(
          handlerName: 'SetContentHeight',
          callback: (args) {
            if (args.isNotEmpty && args[0] is num) {
              final newHeight = args[0].toDouble();
              if (newHeight > 0 && mounted) {
                setState(() {
                  _height = newHeight;
                });
              }
            }
          },
        );
      },
      onReceivedError: (controller, request, error) {
        if (error.type == WebResourceErrorType.NOT_CONNECTED_TO_INTERNET) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('İnternet bağlantınızı kontrol edin.')));
        }
        if (error.type == WebResourceErrorType.CANCELLED) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('İstek iptal edildi.')));
        }
        if (error.type == WebResourceErrorType.UNKNOWN) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bilinmeyen hata oluştu.')));
        }
        if (error.type == WebResourceErrorType.TIMEOUT) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('İstek zaman aşımına uğradı.')));
        }
        if (error.type == WebResourceErrorType.UNSUPPORTED_SCHEME) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Desteklenmeyen şema hatası.')));
        }
      },
    );
  }
}
