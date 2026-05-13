import 'package:flutter/material.dart';

/// Aurora Glass — light + dark (getColabbb `globals.css`). [setBrightness] is driven from the app root from [ThemeMode].
class AppColors {
  AppColors._();

  static Brightness _brightness = Brightness.dark;
  static Brightness get brightness => _brightness;
  static void setBrightness(Brightness b) {
    _brightness = b;
  }

  static bool get _l => _brightness == Brightness.light;

  static Color get primary => _l ? const Color(0xFF5847E8) : const Color(0xFF8F7DFF);
  static Color get primaryVivid => _l ? const Color(0xFF5847E8) : const Color(0xFF6A55FF);
  static Color get primaryLight => _l ? const Color(0xFFE0D9FF) : const Color(0xFF2A2447);
  static Color get secondary => const Color(0xFF8FD4C1);
  static Color get secondaryLight => _l ? const Color(0xFFD4F2E8) : const Color(0xFF152E32);

  static Color get background => _l ? const Color(0xFFF2EFFA) : const Color(0xFF0B0A1A);
  static Color get background2 => _l ? const Color(0xFFE6E1F5) : const Color(0xFF12102A);

  static Color get surface => _l ? const Color(0xFAFFFFFF) : const Color(0xFA231E41);
  static Color get surfaceSolid => _l ? const Color(0xFFFCFAFF) : const Color(0xFF231E41);
  static Color get surfaceVariant => _l ? const Color(0xFFF0EBF8) : const Color(0xFF2A2452);

  static Color get glassCard => _l ? const Color(0x8CFFFFFF) : const Color(0x8C1E1937);
  static Color get glassBorder => _l ? const Color(0x4DFFFFFF) : const Color(0x1AFFFFFF);
  static Color get glassOverlay => _l ? const Color(0x0D131326) : const Color(0x0DFFFFFF);

  static Color get textPrimary => _l ? const Color(0xFF131326) : const Color(0xFFEEE8FF);
  static Color get textSecondary => _l ? const Color(0xB3131926) : const Color(0xFFB8B5C8);
  static Color get textHint => _l ? const Color(0x73131926) : const Color(0xFF6A6788);

  static Color get success => _l ? const Color(0xFF059669) : const Color(0xFF34D399);
  static Color get successLight => _l ? const Color(0xFFD1FAE5) : const Color(0xFF0D1F16);
  static Color get warning => const Color(0xFFFBBF24);
  static Color get warningLight => _l ? const Color(0xFFFEF3C7) : const Color(0xFF1E1505);
  static Color get error => _l ? const Color(0xFFDC2626) : const Color(0xFFF87171);
  static Color get errorLight => _l ? const Color(0xFFFEE2E2) : const Color(0xFF1F0A0A);

  static Color get instagram => const Color(0xFFE1306C);
  static Color get instagramLight => _l ? const Color(0xFFFCE7EF) : const Color(0xFF220010);
  static const Color youtube = Color(0xFFFF0000);
  static Color get youtubeLight => _l ? const Color(0xFFFFE4E4) : const Color(0xFF1F0000);

  static Color get border => _l ? const Color(0x1A131326) : const Color(0x1AFFFFFF);
  static Color get divider => _l ? const Color(0x14131926) : const Color(0x0DFFFFFF);

  static Color get blobViolet => _l ? const Color(0xFF9B8BFF) : const Color(0xFF6A55FF);
  static Color get blobTeal => _l ? const Color(0xFF8FD4C1) : const Color(0xFF2A5A6A);
  static Color get blobIndigo => _l ? const Color(0xFFC4B0FF) : const Color(0xFF2A2470);
  static Color get blobSoft => _l ? const Color(0xFFD9D0F0) : const Color(0xFFC4B0FF);

  static LinearGradient get brandGradient => LinearGradient(
        colors: _l
            ? const [Color(0xFF5847E8), Color(0xFF8F7DFF), Color(0xFF8FD4C1)]
            : const [Color(0xFF6A55FF), Color(0xFF8F7DFF), Color(0xFF8FD4C1)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get brandGradientVertical => LinearGradient(
        colors: _l
            ? const [Color(0xFF5847E8), Color(0xFF8F7DFF), Color(0xFF8FD4C1)]
            : const [Color(0xFF6A55FF), Color(0xFF8F7DFF), Color(0xFF8FD4C1)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );

  static LinearGradient get subtleGradient => LinearGradient(
        colors: _l
            ? const [Color(0xFFE6E1F5), Color(0xFFD9D0F0)]
            : const [Color(0xFF1A1640), Color(0xFF2A2470)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get backgroundGradient => LinearGradient(
        colors: _l
            ? const [Color(0xFFF2EFFA), Color(0xFFE6E1F5), Color(0xFFF2EFFA)]
            : const [Color(0xFF0B0A1A), Color(0xFF12102A), Color(0xFF0B0A1A)],
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

  static LinearGradient get navSelectedGradient => LinearGradient(
        colors: _l
            ? const [Color(0x405847E8), Color(0x408FD4C1)]
            : const [Color(0x268F7DFF), Color(0x268FD4C1)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
}
