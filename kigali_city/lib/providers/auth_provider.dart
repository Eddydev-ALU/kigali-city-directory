import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';


final authServiceProvider = Provider<AuthService>((ref) => AuthService());


final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.read(authServiceProvider).authStateChanges;
});

/// True while [AuthNotifier.signUp] is completing the Firestore profile write
final signupInProgressProvider = StateProvider<bool>((ref) => false);


class AuthState {
  final bool isLoading;
  final String? errorMessage;

  const AuthState({this.isLoading = false, this.errorMessage});

  AuthState copyWith({bool? isLoading, String? errorMessage}) => AuthState(
    isLoading: isLoading ?? this.isLoading,
    errorMessage: errorMessage,
  );
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  final Ref _ref;

  AuthNotifier(this._authService, this._ref) : super(const AuthState());

  Future<bool> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    state = const AuthState(isLoading: true);
    _ref.read(signupInProgressProvider.notifier).state = true;
    try {
      await _authService.signUp(
        email: email,
        password: password,
        displayName: displayName,
      );
      state = const AuthState();
      return true;
    } on Exception catch (e) {
      state = AuthState(errorMessage: _friendlyMessage(e));
      return false;
    } finally {
      _ref.read(signupInProgressProvider.notifier).state = false;
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    state = const AuthState(isLoading: true);
    try {
      await _authService.signIn(email: email, password: password);
      state = const AuthState();
      return true;
    } on Exception catch (e) {
      state = AuthState(errorMessage: _friendlyMessage(e));
      return false;
    }
  }

  Future<void> signOut() async {
    state = const AuthState(isLoading: true);
    try {
      await _authService.signOut();
      state = const AuthState();
    } on Exception catch (e) {
      state = AuthState(errorMessage: _friendlyMessage(e));
    }
  }

  Future<void> resendVerification() async {
    state = const AuthState(isLoading: true);
    try {
      await _authService.resendVerificationEmail();
      state = const AuthState();
    } on Exception catch (e) {
      state = AuthState(errorMessage: _friendlyMessage(e));
    }
  }

  void clearError() => state = state.copyWith(errorMessage: null);

  String _friendlyMessage(Exception e) {
    final msg = e.toString();
    if (msg.contains('email-already-in-use')) {
      return 'An account already exists with that email.';
    } else if (msg.contains('wrong-password') ||
        msg.contains('invalid-credential')) {
      return 'Invalid email or password.';
    } else if (msg.contains('user-not-found')) {
      return 'No account found for that email.';
    } else if (msg.contains('weak-password')) {
      return 'Password must be at least 6 characters.';
    } else if (msg.contains('network-request-failed')) {
      return 'Network error. Please check your connection.';
    } else if (msg.contains('too-many-requests')) {
      return 'Too many attempts. Please try again later.';
    }
    return 'Something went wrong. Please try again.';
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((
  ref,
) {
  return AuthNotifier(ref.read(authServiceProvider), ref);
});


final currentUserProfileProvider = FutureProvider<UserModel?>((ref) async {
  final user = ref.watch(authStateChangesProvider).asData?.value;
  if (user == null) return null;
  return ref.read(authServiceProvider).getUserProfile(user.uid);
});


final likedListingIdsProvider = StreamProvider<List<String>>((ref) {
  final user = ref.watch(authStateChangesProvider).asData?.value;
  if (user == null) return Stream.value([]);
  return ref.read(authServiceProvider).getLikedListingIds(user.uid);
});
