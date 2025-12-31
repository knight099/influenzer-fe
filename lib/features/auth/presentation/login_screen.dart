import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:influenzer_app/features/auth/application/auth_controller.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 100),
                // Logo and Title
                const Text(
                  'Influenzer',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Connect. Create. Earn.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 100),
                
                // Google Sign In Button
                Consumer(
                  builder: (context, ref, _) {
                    final authState = ref.watch(authControllerProvider);
                    
                    return ElevatedButton.icon(
                      onPressed: authState.isLoading ? null : () async {
                        final userData = await ref.read(authControllerProvider.notifier).signInWithGoogle();
                        
                        if (context.mounted && userData != null) {
                          final role = userData['role']?.toString().toUpperCase();
                          
                          // Navigate based on role
                          if (role == 'BRAND') {
                            context.go('/brand-dashboard');
                          } else if (role == 'CREATOR') {
                            context.go('/creator-dashboard');
                          } else {
                            // No role set, go to role selection
                            context.go('/role-selection');
                          }
                        }
                      },
                      icon: authState.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Image.asset(
                              'assets/google_logo.png',
                              height: 24,
                              errorBuilder: (_, __, ___) => const Icon(Icons.login),
                            ),
                      label: Text(authState.isLoading ? 'Signing in...' : 'Continue with Google'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => context.go('/role-selection'),
                  child: const Text('Continue as Guest'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
