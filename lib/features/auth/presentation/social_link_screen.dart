import 'package:flutter/foundation.dart'; // for kIsWeb
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../application/auth_controller.dart';

class SocialLinkScreen extends ConsumerWidget {
  const SocialLinkScreen({super.key});

  Future<void> _launchAuth(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, webOnlyWindowName: '_self');
    } else {
      debugPrint('Could not launch \$url');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch to keep alive and show UI state
    final authState = ref.watch(authControllerProvider);

    // Listen for side effects (Errors/Success)
    ref.listen(authControllerProvider, (previous, next) {
      if (next.isLoading) {
        // Optional: Indicate loading if using global loader
      } else if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connection Failed: ${next.error}')),
        );
      } else if (next is AsyncData && !next.isLoading) {
         // Success feedback
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account Connected Successfully!')),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect Accounts'),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Link your social profiles to get verified and find better work.',
                  style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 32),
                _SocialButton(
                  label: 'Connect Instagram',
                  icon: Icons.camera_alt, 
                  color: Colors.purple,
                  onTap: authState.isLoading ? () {} : () {
                     const clientId = '816744758013078';
                     
                     // Instagram requires HTTPS redirect. Custom schemes (influenzer://) are often rejected.
                     // We use the production backend URL which handles redirecting to the app.
                     final redirectUri = 'https://influenzer.onrender.com/callback/';
                     
                     const scope = 'instagram_business_basic,instagram_business_manage_messages,instagram_business_manage_comments,instagram_business_content_publish,instagram_business_manage_insights';
                     const state = 'instagram'; // Identify provider on callback
                     
                     final uri = Uri.https('www.instagram.com', '/oauth/authorize', {
                       'client_id': clientId,
                       'redirect_uri': redirectUri,
                       'scope': scope,
                       'response_type': 'code',
                       'state': state,
                       'force_reauth': 'true',
                     });
                     
                     debugPrint('[Instagram OAuth] Opening: ${uri.toString()}');
                     _launchAuth(uri.toString());
                  },
                ),
                const SizedBox(height: 16),
                _SocialButton(
                  label: 'Connect YouTube',
                  icon: Icons.play_arrow,
                  color: Colors.red,
                  onTap: authState.isLoading ? () {} : () {
                     if (!kIsWeb) {
                        // Use Native Google Sign-In on Mobile
                        ref.read(authControllerProvider.notifier).connectYouTube();
                     } else {
                        // Use Manual Web Flow
                        const clientId = '47008398696-bsn5162rp1cl2nie455mmr6vu10fvcog.apps.googleusercontent.com';
                        const redirectUri = 'http://localhost:8081/callback';
                        const scope = 'https://www.googleapis.com/auth/youtube.readonly';
                        const state = 'youtube';
                        
                        final uri = Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
                           'client_id': clientId,
                           'redirect_uri': redirectUri,
                           'response_type': 'code',
                           'scope': scope,
                           'access_type': 'offline',
                           'state': state,
                        });
                        
                        _launchAuth(uri.toString());
                     }
                  },
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: authState.isLoading ? null : () {
                    context.go('/creator-dashboard');
                  },
                  child: const Text('Continue'),
                ),
              ],
            ),
          ),
          if (authState.isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SocialButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 16),
        side: BorderSide(color: color),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: Icon(icon),
      label: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }
}
