import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:influenzer_app/features/auth/application/auth_controller.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(authControllerProvider, (previous, next) {
        if (next is AsyncData && !next.isLoading) {
             context.go('/role-selection');
        }
        if (next is AsyncError) {
             ScaffoldMessenger.of(context).showSnackBar(
                 SnackBar(content: Text('Login Failed: ${next.error}')),
             );
        }
    });

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 48), // Spacer replacement
                // Logo Placeholder
                const Center(
                  child: Icon(Icons.flash_on, size: 80, color: Colors.deepPurple),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Influenzer',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Connect Brands with Top Creators',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 48), // Spacer replacement
                ElevatedButton(
                  onPressed: () {
                      ref.read(authControllerProvider.notifier).signInWithGoogle();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    elevation: 2,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                       Icon(Icons.g_mobiledata, size: 24),
                       SizedBox(width: 8),
                       Flexible(
                         child: FittedBox(
                           fit: BoxFit.scaleDown,
                           child: Text(
                             'Continue with Google',
                             style: TextStyle(fontSize: 16),
                           ),
                         ),
                       ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => context.go('/role-selection'),
                  child: const Text('Login with Email'),
                ),
                const SizedBox(height: 24), // Spacer replacement
              ],
            ),
          ),
        ),
      ),
    );
  }
}
