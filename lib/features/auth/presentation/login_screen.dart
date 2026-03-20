import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:influenzer_app/features/auth/application/auth_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../notifications/data/notification_repository.dart';
import '../../notifications/notification_service.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Deep background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF06060E), Color(0xFF0D0820), Color(0xFF06060E)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Vibrant background blobs — more intense on dark
          Positioned(
            top: -100,
            right: -80,
            child: _GlowBlob(size: 320, color: AppColors.primary.withValues(alpha: 0.35)),
          ),
          Positioned(
            top: size.height * 0.28,
            left: -120,
            child: _GlowBlob(size: 280, color: AppColors.secondary.withValues(alpha: 0.22)),
          ),
          Positioned(
            bottom: -60,
            right: -40,
            child: _GlowBlob(size: 240, color: AppColors.primary.withValues(alpha: 0.18)),
          ),
          Positioned(
            bottom: size.height * 0.3,
            left: size.width * 0.4,
            child: _GlowBlob(size: 160, color: AppColors.secondary.withValues(alpha: 0.15)),
          ),

          // Main content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 48),

                  // Logo pill — glass style
                  ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: AppColors.brandGradient,
                          borderRadius: BorderRadius.circular(50),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.5),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 28, height: 28,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.bolt, color: Colors.white, size: 18),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Influenzer',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 52),

                  // Gradient headline — the showstopper
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFFFFFFFF), Color(0xFFDDD8FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: const Text(
                      'Where Brands\nMeet Creators',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.12,
                        letterSpacing: -1.0,
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Accent underline word with gradient
                  ShaderMask(
                    shaderCallback: (bounds) =>
                        AppColors.brandGradient.createShader(bounds),
                    child: const Text(
                      '— and grow together.',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    'Connect with top creators, launch campaigns,\nand grow your brand — all in one place.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.65,
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Glass proof chips
                  Row(
                    children: [
                      _GlassProofChip(icon: Icons.people_alt_rounded, label: '10K+ Creators'),
                      const SizedBox(width: 10),
                      _GlassProofChip(icon: Icons.campaign_rounded, label: '500+ Brands'),
                      const SizedBox(width: 10),
                      _GlassProofChip(icon: Icons.verified_rounded, label: 'Verified'),
                    ],
                  ),

                  const Spacer(),

                  // Google Sign-In button — glass with glow
                  _GlassGoogleButton(
                    isLoading: authState.isLoading,
                    onPressed: () async {
                      final userData = await ref
                          .read(authControllerProvider.notifier)
                          .signInWithGoogle();
                      if (context.mounted && userData != null) {
                        final notifRepo = ref.read(notificationRepositoryProvider);
                        NotificationService.instance.init(notifRepo).ignore();

                        final role = userData['role']?.toString().toUpperCase();
                        if (role == 'BRAND') {
                          context.go('/brand-dashboard');
                        } else if (role == 'CREATOR') {
                          context.go('/creator-dashboard');
                        } else {
                          context.go('/role-selection');
                        }
                      }
                    },
                  ),

                  const SizedBox(height: 14),

                  // Guest button
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => context.go('/role-selection'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'Browse as Guest',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  Center(
                    child: Text(
                      'By continuing, you agree to our Terms & Privacy Policy',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textHint,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowBlob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Colors.transparent],
          stops: const [0.0, 1.0],
        ),
      ),
    );
  }
}

class _GlassProofChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _GlassProofChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ShaderMask(
                shaderCallback: (b) => AppColors.brandGradient.createShader(b),
                child: Icon(icon, size: 13, color: Colors.white),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassGoogleButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _GlassGoogleButton({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: Container(
        width: double.infinity,
        height: 58,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.18),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.2),
              blurRadius: 24,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(17),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.primary,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/google_logo.png',
                          height: 22,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.g_mobiledata_rounded,
                            color: Colors.red,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Continue with Google',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
