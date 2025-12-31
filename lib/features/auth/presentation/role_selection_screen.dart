import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../application/auth_controller.dart';

class RoleSelectionScreen extends ConsumerWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Text(
                'How do you want to use Influenzer?',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              _RoleCard(
                title: 'I am a Brand',
                description: 'Post jobs, find talent, and manage campaigns.',
                icon: Icons.business,
                color: AppColors.primary,
                onTap: authState.isLoading ? null : () async {
                  // Set role to BRAND
                  await ref.read(authControllerProvider.notifier).setRole('BRAND');
                  if (context.mounted) {
                    context.go('/brand-dashboard');
                  }
                },
              ),
              const SizedBox(height: 16),
              _RoleCard(
                title: 'I am a Creator',
                description: 'Find work, submit proposals, and get paid.',
                icon: Icons.video_camera_back,
                color: AppColors.secondary,
                onTap: authState.isLoading ? null : () async {
                  // Set role to CREATOR
                  await ref.read(authControllerProvider.notifier).setRole('CREATOR');
                  if (context.mounted) {
                    context.push('/social-link');
                  }
                },
              ),
              if (authState.isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 24.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _RoleCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: color.withOpacity(0.1),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
