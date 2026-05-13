import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Full-screen ambient Aurora: base gradient + soft drifting orbs
/// (aligned with getColabbb `globals.css` `.aurora-bg` / `.app-shell` blobs).
class AuroraBackdrop extends StatelessWidget {
  final Widget child;

  const AuroraBackdrop({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(gradient: AppColors.backgroundGradient),
        ),
        const AuroraBlobsLayer(),
        child,
      ],
    );
  }
}

class AuroraBlobsLayer extends StatelessWidget {
  const AuroraBlobsLayer({super.key});

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    final w = MediaQuery.sizeOf(context).width;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: -h * 0.1,
          right: -w * 0.15,
          child: _GlowBlob(size: w * 0.9, color: AppColors.blobViolet.withValues(alpha: 0.4)),
        ),
        Positioned(
          bottom: -h * 0.14,
          left: -w * 0.12,
          child: _GlowBlob(size: w * 0.85, color: AppColors.blobTeal.withValues(alpha: 0.35)),
        ),
        Positioned(
          top: h * 0.3,
          left: w * 0.2,
          child: _GlowBlob(size: w * 0.65, color: AppColors.blobIndigo.withValues(alpha: 0.28)),
        ),
      ],
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
          stops: const [0.0, 0.75],
        ),
      ),
    );
  }
}
