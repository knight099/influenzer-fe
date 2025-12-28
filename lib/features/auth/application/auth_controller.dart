import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_controller.g.dart';

enum UserRole { brand, creator, none }

enum AuthStatus { authenticated, unauthenticated }

@riverpod
class AuthController extends _$AuthController {
  @override
  Future<void> build() async {
    // Initial state setup if needed
  }

  void login() {
    // Mock login logic
  }

  void setRole(UserRole role) {
    // Mock role setting
  }
}
