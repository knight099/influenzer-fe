import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../application/auth_controller.dart';

class CallbackScreen extends ConsumerStatefulWidget {
  final Map<String, String> queryParams;

  const CallbackScreen({super.key, required this.queryParams});

  @override
  ConsumerState<CallbackScreen> createState() => _CallbackScreenState();
}

class _CallbackScreenState extends ConsumerState<CallbackScreen> {
  String _status = 'processing';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleCallback();
    });
  }

  Future<void> _handleCallback() async {
    final code = widget.queryParams['code'];
    final stateParam = widget.queryParams['state'];

    if (code != null && stateParam != null) {
      final provider = stateParam;

      // Use the correct redirect URI based on provider
      final redirectUri = provider == 'instagram'
          ? 'https://qrdba2mpab.ap-south-1.awsapprunner.com/callback/'
          : null; // YouTube native flow uses null → backend defaults to "postmessage"

      try {
        await ref.read(authControllerProvider.notifier).connectSocial(
              provider,
              code,
              redirectUri: redirectUri,
            );

        final state = ref.read(authControllerProvider);
        if (state.hasError) {
          throw state.error!;
        }

        if (mounted) {
          context.go('/creator-dashboard');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Connected $provider successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          String errorMessage = 'Failed to connect $provider';
          if (e.toString().contains('401') ||
              e.toString().contains('Authorization')) {
            errorMessage =
                'Please log in first before linking social accounts';
          }
          setState(() {
            _status = 'error';
            _errorMessage = errorMessage;
          });
          // Auto-navigate after brief delay
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) context.go('/creator-dashboard');
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _status = 'error';
          _errorMessage = 'Authorization failed: No code received';
        });
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) context.go('/creator-dashboard');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_status == 'processing') ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Finalizing connection...'),
            ] else if (_status == 'error') ...[
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _errorMessage ?? 'An error occurred',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text(
                'Redirecting...',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
