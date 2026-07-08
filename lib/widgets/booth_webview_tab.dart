import 'dart:io' show Platform;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_windows/webview_windows.dart' as win;

const boothHomeUrl = 'https://booth.pm/';

/// Boothを直接表示するタブ。
/// Windowsは公式webview_flutterが未対応のため webview_windows(WebView2) を使用し、
/// Android/iOSは webview_flutter を使用する。
/// 外部から loadUrl() で任意のURLへ遷移でき、getCurrentUrl() で表示中のURLを取得できる。
class BoothWebViewTab extends StatefulWidget {
  final ValueChanged<String>? onUrlChanged;

  const BoothWebViewTab({super.key, this.onUrlChanged});

  @override
  State<BoothWebViewTab> createState() => BoothWebViewTabState();
}

class BoothWebViewTabState extends State<BoothWebViewTab> {
  bool get _useWindowsWebview => !kIsWeb && Platform.isWindows;

  // モバイル用
  WebViewController? _mobileController;

  // Windows用
  final win.WebviewController _windowsController = win.WebviewController();
  StreamSubscription<String>? _windowsUrlSub;
  bool _windowsReady = false;
  String? _windowsError;

  String currentUrl = boothHomeUrl;

  @override
  void initState() {
    super.initState();
    if (_useWindowsWebview) {
      _initWindows();
    } else {
      _mobileController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(NavigationDelegate(
          onPageFinished: (url) {
            currentUrl = url;
            widget.onUrlChanged?.call(url);
          },
        ))
        ..loadRequest(Uri.parse(boothHomeUrl));
    }
  }

  Future<void> _initWindows() async {
    try {
      await _windowsController.initialize();
      _windowsUrlSub = _windowsController.url.listen((url) {
        currentUrl = url;
        widget.onUrlChanged?.call(url);
      });
      await _windowsController.loadUrl(boothHomeUrl);
      if (mounted) setState(() => _windowsReady = true);
    } catch (e) {
      if (mounted) setState(() => _windowsError = e.toString());
    }
  }

  /// 指定URLへ遷移する（一覧からアイテムをタップした際などに使用）
  Future<void> loadUrl(String url) async {
    currentUrl = url;
    if (_useWindowsWebview) {
      await _windowsController.loadUrl(url);
    } else {
      await _mobileController?.loadRequest(Uri.parse(url));
    }
  }

  Future<void> reload() async {
    if (_useWindowsWebview) {
      await _windowsController.reload();
    } else {
      await _mobileController?.reload();
    }
  }

  Future<void> goBack() async {
    if (_useWindowsWebview) {
      await _windowsController.goBack();
    } else {
      if (await _mobileController?.canGoBack() ?? false) {
        await _mobileController?.goBack();
      }
    }
  }

  @override
  void dispose() {
    _windowsUrlSub?.cancel();
    if (_useWindowsWebview) {
      _windowsController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_useWindowsWebview) {
      if (_windowsError != null) {
        return _ErrorView(
          message: 'WebView2の初期化に失敗しました。\n'
              'Microsoft Edge WebView2 Runtimeがインストールされているか確認してください。\n\n$_windowsError',
        );
      }
      if (!_windowsReady) {
        return const Center(child: CircularProgressIndicator());
      }
      return win.Webview(_windowsController);
    }

    return WebViewWidget(controller: _mobileController!);
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
      ),
    );
  }
}
