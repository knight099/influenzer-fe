import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../application/auth_controller.dart';
import 'instagram_auth_webview.dart';

class SocialLinkScreen extends ConsumerWidget {
  const SocialLinkScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    ref.listen(authControllerProvider, (previous, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connection Failed: ${next.error}')),
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
                  onTap: authState.isLoading
                      ? () {}
                      : () async {
                          final result =
                              await Navigator.of(context).push<InstagramAuthResult>(
                            MaterialPageRoute(
                              fullscreenDialog: true,
                              builder: (_) => InstagramAuthWebView.instagram(),
                            ),
                          );
                          if (!context.mounted) return;
                          if (result?.success == true) {
                            await ref
                                .read(authControllerProvider.notifier)
                                .connectSocial(
                              'instagram',
                              result!.code!,
                              redirectUri: 'https://influenzer.onrender.com/callback/',
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Instagram connected successfully!'),
                                ),
                              );
                            }
                          } else if (result?.error != null &&
                              result!.error != 'Cancelled') {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Connection failed: ${result.error}'),
                              ),
                            );
                          }
                        },
                ),
                const SizedBox(height: 16),
                _SocialButton(
                  label: 'Connect YouTube',
                  icon: Icons.play_arrow,
                  color: Colors.red,
                  onTap: authState.isLoading
                      ? () {}
                      : () {
                          if (!kIsWeb) {
                            ref.read(authControllerProvider.notifier).connectYouTube();
                          } else {
                            const clientId =
                                '47008398696-bsn5162rp1cl2nie455mmr6vu10fvcog.apps.googleusercontent.com';
                            const redirectUri = 'http://localhost:8081/callback';
                            const scope =
                                'https://www.googleapis.com/auth/youtube.readonly https://www.googleapis.com/auth/yt-analytics.readonly';
                            const state = 'youtube';

                            final uri = Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
                              'client_id': clientId,
                              'redirect_uri': redirectUri,
                              'response_type': 'code',
                              'scope': scope,
                              'access_type': 'offline',
                              'state': state,
                            });

                            launchUrl(Uri.parse(uri.toString()),
                                webOnlyWindowName: '_self');
                          }
                        },
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: authState.isLoading
                      ? null
                      : () {
                          context.go('/creator-dashboard');
                        },
                  child: const Text('Continue'),
                ),
              ],
            ),
          ),
          if (authState.isLoading) const Center(child: CircularProgressIndicator()),
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
      label:
          Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }
}
