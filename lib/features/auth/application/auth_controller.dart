import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:influenzer_app/features/auth/data/auth_repository.dart';
import 'package:google_sign_in/google_sign_in.dart';

part 'auth_controller.g.dart';

enum UserRole { brand, creator, none }

enum AuthStatus { authenticated, unauthenticated }

@riverpod
class AuthController extends _$AuthController {
  @override
  Future<void> build() async {
    // Initial state setup if needed
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => ref.read(authRepositoryProvider).login(email, password));
  }

  Future<void> register(String email, String password, String role) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => ref.read(authRepositoryProvider).register(email, password, role));
  }

  Future<Map<String, dynamic>?> signInWithGoogle() async {
    state = const AsyncValue.loading();
    
    Map<String, dynamic>? userData;
    state = await AsyncValue.guard(() async {
      final googleSignIn = GoogleSignIn();
      final googleUser = await googleSignIn.signIn();
      if (googleUser != null) {
        final googleAuth = await googleUser.authentication;
        final idToken = googleAuth.idToken;
        final accessToken = googleAuth.accessToken;
        
        // Get user profile info from Google
        final displayName = googleUser.displayName;
        final photoUrl = googleUser.photoUrl;
        
        if (idToken != null) {
           userData = await ref.read(authRepositoryProvider).socialLogin(
             'google', 
             idToken,
             name: displayName,
             avatarUrl: photoUrl,
           );
        } else if (accessToken != null) {
           // Fallback to access token if idToken is not available (common on Web)
           userData = await ref.read(authRepositoryProvider).socialLogin(
             'google', 
             accessToken,
             name: displayName,
             avatarUrl: photoUrl,
           );
        } else {
           throw Exception('Google Sign-In failed: No ID Token or Access Token found');
        }
      } else {
         // User canceled
      }
    });
    
    return userData;
  }
  
  Future<void> connectSocial(String provider, String token, {String? redirectUri}) async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(() => ref.read(authRepositoryProvider).connectSocial(provider, token, redirectUri: redirectUri));
    // Check if the ref is still mounted before updating state
    if (ref.mounted) {
      state = result;
    }
  }

  Future<void> connectYouTube() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final googleSignIn = GoogleSignIn(
        // Must use Web Client ID as serverClientId to get a valid serverAuthCode
        serverClientId: '47008398696-bsn5162rp1cl2nie455mmr6vu10fvcog.apps.googleusercontent.com',
        scopes: ['https://www.googleapis.com/auth/youtube.readonly'],
        forceCodeForRefreshToken: true,
      );
      
      // Force sign out first to allow user to pick account
      await googleSignIn.signOut();
      
      final googleUser = await googleSignIn.signIn();
      if (googleUser != null) {
        // serverAuthCode should now be populated
        final token = googleUser.serverAuthCode;
        
        if (token != null) {
          // Send empty string for redirectUri as native flow doesn't use one
          await ref.read(authRepositoryProvider).connectSocial('youtube', token, redirectUri: '');
        } else {
           throw Exception('Failed to get server auth code from Google. Check Web Client ID configuration.');
        }
      }
    });
  }

  Future<void> setRole(String role) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => ref.read(authRepositoryProvider).setRole(role));
  }
}
