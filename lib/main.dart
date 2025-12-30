import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/network/api_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  
  // Restore auth token from storage on app startup
  await _initializeAuth();
  
  runApp(const ProviderScope(child: InfluenzerApp()));
}

/// Initialize auth by restoring token from SharedPreferences
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

    return MaterialApp.router(
      title: 'Influenzer',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

