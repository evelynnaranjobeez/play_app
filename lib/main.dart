import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Forzar orientación horizontal
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  InAppLocalhostServer? localhostServer;

  if (!kIsWeb) {
    localhostServer = InAppLocalhostServer(documentRoot: 'assets/offline_page');
    await localhostServer.start();
  }

  runApp(MyApp(localhostServer: localhostServer));
}

void requestBluetoothPermissions() async {
  if (!kIsWeb) {
    if (await Permission.bluetoothConnect.isDenied) {
      await Permission.bluetoothConnect.request();
    }
    if (await Permission.bluetooth.isDenied) {
      await Permission.bluetooth.request();
    }
  }
}

class MyApp extends StatelessWidget {
  final InAppLocalhostServer? localhostServer;

  const MyApp({super.key, this.localhostServer});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Offline Page',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: WebViewExample(localhostServer: localhostServer),
    );
  }
}

class WebViewExample extends StatefulWidget {
  final InAppLocalhostServer? localhostServer;

  const WebViewExample({super.key, this.localhostServer});

  @override
  State<WebViewExample> createState() => _WebViewExampleState();
}

class _WebViewExampleState extends State<WebViewExample> {
  WebViewController? controller;
  int progress = 0;

  @override
  void initState() {
    super.initState();

    requestBluetoothPermissions();

    if (!kIsWeb) {
      controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(onProgress: (int p) {
            setState(() {
              progress = p;
            });
          }, onPageStarted: (String url) {
            debugPrint("Página iniciada: $url");
          }, onPageFinished: (String url) {
            debugPrint("Página cargada: $url");
          }),
        )
        ..loadFlutterAsset('assets/offline_page/genially.html');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Offline Page (Web)'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => setState(() {}),
            ),
          ],
        ),
        body: InAppWebView(
          initialFile: "assets/genially.html",
          initialOptions: InAppWebViewGroupOptions(
            crossPlatform: InAppWebViewOptions(
              javaScriptEnabled: true,
              allowFileAccessFromFileURLs: true,
              allowUniversalAccessFromFileURLs: true,
            ),
          ),
        ),
      );
    } else {
      return Scaffold(
        body: controller == null
            ? const Center(child: CircularProgressIndicator())
            : WebViewWidget(controller: controller!),
      );
    }
  }
}
