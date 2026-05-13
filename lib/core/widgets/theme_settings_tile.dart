import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../theme/theme_mode_provider.dart';

/// Settings row: dark mode on/off (Aurora night vs day). Used on creator + brand profile.
class ThemeSettingsTile extends ConsumerWidget {
  const ThemeSettingsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dark mode',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isDark ? 'Aurora night' : 'Aurora day',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: isDark,
                onChanged: (v) {
                  ref.read(themeModeProvider.notifier).setDark(v);
                },
                activeTrackColor: AppColors.primary.withValues(alpha: 0.35),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 70, right: 16),
          child: Divider(height: 1, color: AppColors.divider),
        ),
      ],
    );
  }
}
