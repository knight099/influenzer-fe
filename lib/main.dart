import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/theme_mode_provider.dart';
import 'core/network/api_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  final prefs = await SharedPreferences.getInstance();
  await loadInitialThemeFromPrefs(prefs);
  AppColors.setBrightness(brightnessFor(kInitialUserThemeMode));
  _applySystemChrome();

  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('[Firebase] Init skipped: $e');
  }

  await _initializeAuth();

  runApp(const ProviderScope(child: InfluenzerApp()));
}

void _applySystemChrome() {
  final dark = AppColors.brightness == Brightness.dark;
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
    statusBarBrightness: dark ? Brightness.dark : Brightness.light,
    systemNavigationBarColor: AppColors.background,
    systemNavigationBarIconBrightness: dark ? Brightness.light : Brightness.dark,
  ));
}

Future<void> _initializeAuth() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final storedToken = prefs.getString('auth_token');
    if (storedToken != null && storedToken.isNotEmpty) {
      AuthTokenHolder.setToken(storedToken);
      debugPrint('[Auth] Restored token from storage');
    }
  } catch (e) {
    debugPrint('[Auth] Failed to restore token: $e');
  }
}

class InfluenzerApp extends ConsumerWidget {
  const InfluenzerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    final mode = ref.watch(themeModeProvider);
    AppColors.setBrightness(brightnessFor(mode));
    WidgetsBinding.instance.addPostFrameCallback((_) => _applySystemChrome());

    return MaterialApp.router(
      title: 'GetColabb',
      theme: AppTheme.auroraLight,
      darkTheme: AppTheme.auroraDark,
      themeMode: mode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
