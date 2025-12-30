import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../application/auth_controller.dart';

class CallbackScreen extends ConsumerStatefulWidget {
  final Map<String, String> queryParams;

  const CallbackScreen({super.key, required this.queryParams});

  @override
  ConsumerState<CallbackScreen> createState() => _CallbackScreenState();
}

class _CallbackScreenState extends ConsumerState<CallbackScreen> {
  @override
  void initState() {
    super.initState();
    // Defer the callback until after the widget tree is built
    // to avoid modifying providers during build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleCallback();
    });
  }

  Future<void> _handleCallback() async {
    // Check if we are on the ngrok domain (HTTPS) and redirect back to localhost (HTTP)
    // This is necessary to avoid "Mixed Content" errors since the backend is on HTTP
    final currentUri = Uri.base;
    if (currentUri.host.contains('ngrok') && currentUri.scheme == 'https') {
      debugPrint('[Callback] Detected ngrok origin. Redirecting to localhost...');
      
      final localhostUri = currentUri.replace(
        scheme: 'http',
        host: 'localhost',
        port: 8081,
      );
      
      await launchUrl(localhostUri, webOnlyWindowName: '_self');
      return;
    }

    final code = widget.queryParams['code'];
    final stateParam = widget.queryParams['state']; // We use 'state' to know which provider it was

    if (code != null && stateParam != null) {
      // Platform is passed in 'state' parameter (e.g. 'instagram', 'youtube')
      final provider = stateParam; 
      
      // Use the correct redirect URI based on provider
      final redirectUri = provider == 'instagram' 
          ? 'https://c03ca07f4f02.ngrok-free.app/callback'
          : 'http://localhost:8081/callback';
      
      try {
        // Call the controller to connect
        await ref.read(authControllerProvider.notifier).connectSocial(provider, code, redirectUri: redirectUri);
        
        if (mounted) {
           // Determine where to go next
           // For now, go back to social link or dashboard
           context.go('/social-link'); 
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Connected $provider successfully!')),
           );
        }
      } catch (e) {
        if (mounted) {
          String errorMessage = 'Failed to connect $provider';
          if (e.toString().contains('401') || e.toString().contains('Authorization')) {
            errorMessage = 'Please log in first before linking social accounts';
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
          );
          context.go('/social-link');
        }
      }
    } else {
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Authorization failed: No code received')),
         );
         context.go('/social-link');
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNgrok = Uri.base.host.contains('ngrok');
    
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Finalizing connection...'),
            if (isNgrok) ...[
              const SizedBox(height: 24),
              const Text('Redirecting to local app...', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  final currentUri = Uri.base;
                  final localhostUri = currentUri.replace(
                    scheme: 'http',
                    host: 'localhost',
                    port: 8081,
                  );
                  launchUrl(localhostUri, webOnlyWindowName: '_self');
                },
                child: const Text('Click here if not redirected'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
