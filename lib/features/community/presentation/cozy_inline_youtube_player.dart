import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

/// In-app 16:9 YouTube Video Player (stays 100% inside ERAT — never diverts child to external YouTube app)
class CozyInlineYoutubePlayer extends StatefulWidget {
  final String videoId;
  final String fallbackEmoji;

  const CozyInlineYoutubePlayer({
    super.key,
    required this.videoId,
    required this.fallbackEmoji,
  });

  @override
  State<CozyInlineYoutubePlayer> createState() =>
      _CozyInlineYoutubePlayerState();
}

class _CozyInlineYoutubePlayerState extends State<CozyInlineYoutubePlayer> {
  static const Color _mochaPrimary = Color(0xFF6D4C41);
  static const Color _blushSurface = Color(0xFFF5E4DC);

  WebViewController? _controller;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    if (kIsWeb) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      return;
    }

    try {
      late final PlatformWebViewControllerCreationParams params;
      if (WebViewPlatform.instance is WebKitWebViewPlatform) {
        params = WebKitWebViewControllerCreationParams(
          allowsInlineMediaPlayback: true,
          mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
        );
      } else {
        params = const PlatformWebViewControllerCreationParams();
      }

      final controller = WebViewController.fromPlatformCreationParams(params)
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.black)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (_) {
              if (mounted) setState(() => _isLoading = false);
            },
            onWebResourceError: (_) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                  _hasError = true;
                });
              }
            },
            // Keep child strictly inside the embedded player — block external YouTube navigation
            onNavigationRequest: (request) {
              final url = request.url;
              if (url.startsWith('https://www.youtube-nocookie.com/embed/') ||
                  url.startsWith('https://www.youtube.com/embed/') ||
                  url.startsWith('about:blank')) {
                return NavigationDecision.navigate;
              }
              return NavigationDecision.prevent;
            },
          ),
        );

      final html = '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <style>
    html, body { margin: 0; padding: 0; width: 100%; height: 100%; background: #000; overflow: hidden; }
    iframe { width: 100%; height: 100%; border: 0; }
  </style>
</head>
<body>
  <iframe
    src="https://www.youtube-nocookie.com/embed/${widget.videoId}?playsinline=1&rel=0&modestbranding=1&fs=1"
    allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
    allowfullscreen>
  </iframe>
</body>
</html>
''';

      controller.loadHtmlString(
        html,
        baseUrl: 'https://www.youtube-nocookie.com',
      );
      _controller = controller;
    } catch (_) {
      _isLoading = false;
      _hasError = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: Colors.black,
          child: _hasError || _controller == null
              ? Container(
                  color: _blushSurface,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.fallbackEmoji,
                        style: const TextStyle(fontSize: 38),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'In-app video player requires a mobile build (flutter run).',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _mochaPrimary,
                        ),
                      ),
                    ],
                  ),
                )
              : Stack(
                  children: [
                    WebViewWidget(controller: _controller!),
                    if (_isLoading)
                      Container(
                        color: Colors.black.withValues(alpha: 0.35),
                        alignment: Alignment.center,
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}
