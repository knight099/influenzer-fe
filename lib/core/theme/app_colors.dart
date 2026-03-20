import 'package:flutter/material.dart';

class AppColors {
  // Primary brand gradient — violet to rose (brand identity)
  static const Color primary = Color(0xFF7C3AED);
  static const Color primaryLight = Color(0xFF1C1040); // Dark violet chip bg
  static const Color secondary = Color(0xFFEC4899);
  static const Color secondaryLight = Color(0xFF250B2B); // Dark rose chip bg

  // Dark glass backgrounds
  static const Color background = Color(0xFF06060E);      // Near-black with purple soul
  static const Color surface = Color(0xFF0E0E22);         // Dark surface for cards
  static const Color surfaceVariant = Color(0xFF160E30);  // Purple-tinted variant

  // Glass surfaces (for BackdropFilter use)
  static const Color glassCard = Color(0x0FFFFFFF);       // ~6% white
  static const Color glassBorder = Color(0x1AFFFFFF);     // ~10% white border
  static const Color glassOverlay = Color(0x0AFFFFFF);    // ~4% white overlay

  // Text — high contrast for dark backgrounds
  static const Color textPrimary = Color(0xFFEEEEFF);     // Near-white, slightly blue
  static const Color textSecondary = Color(0xFF9898BB);   // Muted lavender
  static const Color textHint = Color(0xFF5C5C7F);        // Subtle purple-grey

  // Status — vibrant on dark
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFF071A0E);    // Dark green tint
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFF1E1505);    // Dark amber tint
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFF1F0808);      // Dark red tint

  // Platform colors
  static const Color instagram = Color(0xFFE1306C);
  static const Color instagramLight = Color(0xFF220010);  // Dark instagram tint
  static const Color youtube = Color(0xFFFF0000);
  static const Color youtubeLight = Color(0xFF1F0000);    // Dark youtube tint

  // Divider & border — subtle white lines on dark
  static const Color border = Color(0x1AFFFFFF);          // 10% white
  static const Color divider = Color(0x0DFFFFFF);         // 5% white

  // Gradient presets
  static const LinearGradient brandGradient = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient brandGradientVertical = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Dark subtle gradient for empty icon containers
  static const LinearGradient subtleGradient = LinearGradient(
    colors: [Color(0xFF1A1040), Color(0xFF2A0E40)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // App background gradient (subtle depth)
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF060612), Color(0xFF0E0824)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient youtubeGradient = LinearGradient(
    colors: [Color(0xFFFF0000), Color(0xFFFF6B6B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient instagramGradient = LinearGradient(
    colors: [Color(0xFF833AB4), Color(0xFFE1306C), Color(0xFFF77737)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Selected nav item gradient overlay (15% opacity)
  static const LinearGradient navSelectedGradient = LinearGradient(
    colors: [Color(0x267C3AED), Color(0x26EC4899)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
