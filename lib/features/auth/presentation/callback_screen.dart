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
    // Check for ngrok/web environment to decide whether to handle code or redirect
    final currentUri = Uri.base;
    final isNgrok = currentUri.host.contains('ngrok') && currentUri.scheme == 'https';

    // If on ngrok, we are likely in the browser on mobile after Instagram redirect.
    // We should try to open the app via deep link.
    if (isNgrok) {
      debugPrint('[Callback] Detected ngrok origin. Waiting for user action or auto-redirect...');
      // We don't auto-redirect immediately to allow user to see the button if auto-launch fails
      return;
    }

    final code = widget.queryParams['code'];
    final stateParam = widget.queryParams['state']; // We use 'state' to know which provider it was

    if (code != null && stateParam != null) {
      // Platform is passed in 'state' parameter (e.g. 'instagram', 'youtube')
      final provider = stateParam; 
      
      // Use the correct redirect URI based on provider
      final redirectUri = provider == 'instagram' 
          ? 'https://influenzer.onrender.com/callback/'
          : 'http://localhost:8081/callback';
      
      try {
        // Call the controller to connect
        await ref.read(authControllerProvider.notifier).connectSocial(provider, code, redirectUri: redirectUri);
        
        // Check for error in state
        final state = ref.read(authControllerProvider);
        if (state.hasError) {
          throw state.error!;
        }
        
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
              const Text('Successfully authorized!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.touch_app),
                label: const Text('Open in App'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                onPressed: () async {
                  // Construct Deep Link: influenzer://callback?code=...&state=...
                  // We copy the query parameters from the current URL
                  final deepLink = Uri(
                    scheme: 'influenzer',
                    host: 'callback',
                    queryParameters: widget.queryParams,
                  );
                  debugPrint('Launching deep link: $deepLink');
                  
                  if (await canLaunchUrl(deepLink)) {
                    await launchUrl(deepLink);
                  } else {
                     ScaffoldMessenger.of(context).showSnackBar(
                       const SnackBar(content: Text('Could not open app. Is it installed?')),
                     );
                  }
                },
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                   final currentUri = Uri.base;
                   final localhostUri = currentUri.replace(
                     scheme: 'http',
                     host: 'localhost',
                     port: 8081,
                   );
                   launchUrl(localhostUri, webOnlyWindowName: '_self');
                }, 
                child: const Text('Continue in Browser (Dev Only)'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
