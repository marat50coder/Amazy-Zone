import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../theme.dart';

class WebDocScreen extends StatefulWidget {
  const WebDocScreen({
    super.key,
    required this.title,
    required this.url,
  });

  final String title;
  final String url;

  @override
  State<WebDocScreen> createState() => _WebDocScreenState();
}

class _WebDocScreenState extends State<WebDocScreen> {
  late final WebViewController _controller;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AmazyTheme.bgDark)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int p) => setState(() => _progress = p / 100.0),
          onPageFinished: (_) => setState(() => _progress = 1.0),
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AmazyTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AmazyTheme.panelDark,
        foregroundColor: Colors.white,
        title: Text(
          widget.title,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
        iconTheme: const IconThemeData(color: AmazyTheme.accentOrangeGlow),
      ),
      body: Column(
        children: <Widget>[
          if (_progress < 1.0)
            LinearProgressIndicator(
              value: _progress,
              backgroundColor: AmazyTheme.panelDark,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AmazyTheme.accentOrange),
              minHeight: 2,
            ),
          Expanded(child: WebViewWidget(controller: _controller)),
        ],
      ),
    );
  }
}
