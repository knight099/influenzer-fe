import 'dart:math';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/theme/app_colors.dart';

/// Result returned when the WebView completes (success or failure).
class InstagramAuthResult {
  final String? code;
  final String? error;
  bool get success => code != null && error == null;

  const InstagramAuthResult.success(this.code) : error = null;
  const InstagramAuthResult.failure(this.error) : code = null;
}

/// Full-screen in-app WebView for Instagram OAuth.
/// Intercepts the redirect to [redirectUri] and extracts the auth code
/// without ever leaving the app.
class InstagramAuthWebView extends StatefulWidget {
  final String authUrl;
  final String redirectUri;
  final String? expectedState;

  const InstagramAuthWebView({
    super.key,
    required this.authUrl,
    required this.redirectUri,
    this.expectedState,
  });

  /// Convenience constructor that builds the Instagram OAuth URL.
  factory InstagramAuthWebView.instagram({Key? key}) {
    // OLD app: const clientId = '816744758013078';
    const clientId = '4234043196818678'; // getcolabb-IG
    const redirectUri = 'https://api.getcolabb.com/callback/';
    const scope =
        'instagram_business_basic,instagram_business_manage_messages,'
        'instagram_business_manage_comments,instagram_business_content_publish,'
        'instagram_business_manage_insights';

    // Generate a random state nonce for CSRF protection
    final random = Random.secure();
    final stateNonce = 'instagram_${List.generate(16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join()}';

    final uri = Uri.https('www.instagram.com', '/oauth/authorize', {
      'client_id': clientId,
      'redirect_uri': redirectUri,
      'scope': scope,
      'response_type': 'code',
      'state': stateNonce,
    });

    return InstagramAuthWebView(
      key: key,
      authUrl: uri.toString(),
      redirectUri: redirectUri,
      expectedState: stateNonce,
    );
  }

  @override
  State<InstagramAuthWebView> createState() => _InstagramAuthWebViewState();
}

class _InstagramAuthWebViewState extends State<InstagramAuthWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasHandled = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) => setState(() => _isLoading = false),
          onWebResourceError: (error) {
            // Ignore errors from intercepted URLs (net::ERR_ABORTED is expected)
            if (error.errorCode == -3) return;
            setState(() => _isLoading = false);
          },
          onNavigationRequest: (request) {
            final url = request.url;

            // Intercept the redirect URI
            if (url.startsWith(widget.redirectUri) && !_hasHandled) {
              _hasHandled = true;
              final uri = Uri.parse(url);
              final code = uri.queryParameters['code'];
              final error = uri.queryParameters['error'];
              final returnedState = uri.queryParameters['state'];

              // Validate CSRF state nonce if we set one
              if (widget.expectedState != null &&
                  returnedState != widget.expectedState) {
                Navigator.of(context).pop(
                  const InstagramAuthResult.failure('State mismatch — possible CSRF attack'),
                );
                return NavigationDecision.prevent;
              }

              if (code != null) {
                Navigator.of(context).pop(InstagramAuthResult.success(code));
              } else {
                Navigator.of(context).pop(
                  InstagramAuthResult.failure(error ?? 'Authorization denied'),
                );
              }
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.authUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(
            const InstagramAuthResult.failure('Cancelled'),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24, height: 24,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF58529), Color(0xFFDD2A7B), Color(0xFF8134AF)],
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Text(
              'Connect Instagram',
              style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        centerTitle: true,
        bottom: _isLoading
            ? PreferredSize(
                preferredSize: const Size.fromHeight(3),
                child: LinearProgressIndicator(
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation(AppColors.instagram),
                  minHeight: 3,
                ),
              )
            : null,
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
