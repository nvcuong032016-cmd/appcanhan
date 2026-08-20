import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MrCuongApp());
}

class MrCuongApp extends StatefulWidget {
  const MrCuongApp({super.key});
  @override
  State<MrCuongApp> createState() => _MrCuongAppState();
}

class _MrCuongAppState extends State<MrCuongApp> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0B0F17))
      ..loadFlutterAsset('assets/mr_cuong.html');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mr Cường',
      theme: ThemeData.dark(useMaterial3: true),
      home: Scaffold(
        body: SafeArea(child: WebViewWidget(controller: _controller)),
      ),
    );
  }
}
