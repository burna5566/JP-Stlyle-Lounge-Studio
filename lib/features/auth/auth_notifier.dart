import 'package:appwrite/models.dart' as appwrite_models;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/appwrite/appwrite_client_factory.dart';
import '../../core/appwrite/appwrite_config.dart';
import 'auth_repository.dart';
import 'user_repository.dart';

// ── Providers ────────────────────────────────────────────────────────────────

final _clientFactoryProvider = Provider<AppwriteClientFactory>((ref) {
  return AppwriteClientFactory(AppwriteConfig.fromEnv());
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(_clientFactoryProvider));
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(ref.watch(_clientFactoryProvider));
});

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((
  ref,
) {
  return AuthNotifier(
    authRepo: ref.watch(authRepositoryProvider),
    userRepo: ref.watch(userRepositoryProvider),
  );
});

// ── State ─────────────────────────────────────────────────────────────────────

sealed class AuthState {
  const AuthState();
}

/// Initial state — session check not yet run.
class AuthStateLoading extends AuthState {
  const AuthStateLoading();
}

/// No active session (or guest).
class AuthStateUnauthenticated extends AuthState {
  const AuthStateUnauthenticated({this.isGuest = false});
  final bool isGuest;
}

/// Authenticated but profile not yet complete.
class AuthStateNeedsProfile extends AuthState {
  const AuthStateNeedsProfile({required this.accountUser, this.pendingPhone});
  final appwrite_models.User accountUser;
  final String? pendingPhone;
}

/// Fully authenticated with a complete profile.
class AuthStateAuthenticated extends AuthState {
  const AuthStateAuthenticated({required this.user});
  final AppUser user;
}

/// An async operation is in progress (login, OTP send, etc.).
class AuthStateWorking extends AuthState {
  const AuthStateWorking({this.message});
  final String? message;
}

/// A recoverable error (wrong OTP, bad credentials, etc.).
class AuthStateError extends AuthState {
  const AuthStateError({required this.message, this.previous});
  final String message;
  final AuthState? previous;
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier({required this.authRepo, required this.userRepo})
    : super(const AuthStateLoading()) {
    checkSession();
  }

  final AuthRepository authRepo;
  final UserRepository userRepo;

  // ── Session Check ──────────────────────────────────────────────────────────

  Future<void> checkSession() async {
    state = const AuthStateLoading();
    try {
      final account = await authRepo.currentUser();
      if (account == null) {
        state = const AuthStateUnauthenticated();
        return;
      }
      await _resolveUserProfile(account);
    } on Object {
      state = const AuthStateUnauthenticated();
    }
  }

  // ── Guest Mode ─────────────────────────────────────────────────────────────

  void continueAsGuest() {
    state = const AuthStateUnauthenticated(isGuest: true);
  }

  // ── Email + Password ───────────────────────────────────────────────────────

  Future<void> registerWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    state = const AuthStateWorking(message: 'Creating account…');
    try {
      await authRepo.createEmailAccount(
        name: name,
        email: email,
        password: password,
      );
      await authRepo.signInWithEmail(email: email, password: password);
      final account = await authRepo.currentUser();
      if (account != null) {
        await _resolveUserProfile(account, nameHint: name, emailHint: email);
      }
    } on Object catch (e) {
      state = AuthStateError(
        message: _friendlyError(e),
        previous: const AuthStateUnauthenticated(),
      );
    }
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AuthStateWorking(message: 'Signing in…');
    try {
      await authRepo.signInWithEmail(email: email, password: password);
      final account = await authRepo.currentUser();
      if (account != null) await _resolveUserProfile(account);
    } on Object catch (e) {
      state = AuthStateError(
        message: _friendlyError(e),
        previous: const AuthStateUnauthenticated(),
      );
    }
  }

  // ── Google OAuth ───────────────────────────────────────────────────────────

  Future<void> signInWithGoogle({
    required String successUrl,
    required String failureUrl,
  }) async {
    state = const AuthStateWorking(message: 'Authenticating with Google…');
    try {
      await authRepo.signInWithGoogle(
        successUrl: successUrl,
        failureUrl: failureUrl,
      );
      final account = await authRepo.currentUser();
      if (account != null) await _resolveUserProfile(account);
    } on Object catch (e) {
      state = AuthStateError(
        message: _friendlyError(e),
        previous: const AuthStateUnauthenticated(),
      );
    }
  }

  // ── Phone OTP ──────────────────────────────────────────────────────────────

  String? _pendingOtpUserId;
  String? _pendingPhone;

  Future<void> sendPhoneOtp(String phone) async {
    state = const AuthStateWorking(message: 'Sending OTP…');
    try {
      _pendingOtpUserId = await authRepo.sendPhoneOtp(phone);
      _pendingPhone = phone;
      state =
          const AuthStateUnauthenticated(); // back to login; OTP screen takes over
    } on Object catch (e) {
      state = AuthStateError(
        message: _friendlyError(e),
        previous: const AuthStateUnauthenticated(),
      );
    }
  }

  Future<void> verifyOtp(String otp) async {
    final userId = _pendingOtpUserId;
    if (userId == null) {
      state = const AuthStateError(
        message: 'Session expired. Please request a new OTP.',
        previous: AuthStateUnauthenticated(),
      );
      return;
    }
    state = const AuthStateWorking(message: 'Verifying OTP…');
    try {
      await authRepo.verifyOtp(userId: userId, otp: otp);
      final account = await authRepo.currentUser();
      if (account != null) {
        await _resolveUserProfile(account, phoneHint: _pendingPhone);
      }
      _pendingOtpUserId = null;
      _pendingPhone = null;
    } on Object catch (e) {
      state = AuthStateError(
        message: _friendlyError(e),
        previous: const AuthStateUnauthenticated(),
      );
    }
  }

  String? get pendingPhone => _pendingPhone;

  // ── Profile Completion ────────────────────────────────────────────────────

  Future<void> completeProfile({
    required String userId,
    required String name,
    String? phone,
  }) async {
    state = const AuthStateWorking(message: 'Saving profile…');
    try {
      final appUser = await userRepo.createUser(
        userId: userId,
        name: name,
        phone: phone,
      );
      state = AuthStateAuthenticated(user: appUser);
    } on Object catch (e) {
      state = AuthStateError(
        message: _friendlyError(e),
        previous: const AuthStateUnauthenticated(),
      );
    }
  }

  // ── Sign Out ───────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    state = const AuthStateWorking(message: 'Signing out…');
    try {
      await authRepo.signOut();
    } on Object {
      // Best-effort; clear state regardless.
    }
    state = const AuthStateUnauthenticated();
  }

  // ── Internal ───────────────────────────────────────────────────────────────

  Future<void> _resolveUserProfile(
    appwrite_models.User account, {
    String? nameHint,
    String? emailHint,
    String? phoneHint,
  }) async {
    AppUser? profile = await userRepo.getUser(account.$id);

    if (profile == null) {
      // First login: auto-create profile so we can route to profile setup
      state = AuthStateNeedsProfile(
        accountUser: account,
        pendingPhone: phoneHint,
      );
      return;
    }

    state = AuthStateAuthenticated(user: profile);
  }

  static String _friendlyError(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('invalid credentials') || msg.contains('401')) {
      return 'Invalid email or password.';
    }
    if (msg.contains('user_already_exists') || msg.contains('409')) {
      return 'An account with this email already exists.';
    }
    if (msg.contains('phone') && msg.contains('invalid')) {
      return 'Invalid phone number. Use format: +233XXXXXXXXX';
    }
    if (msg.contains('rate_limit') || msg.contains('429')) {
      return 'Too many attempts. Please wait a moment.';
    }
    if (msg.contains('network') || msg.contains('socket')) {
      return 'Network error. Check your connection.';
    }
    return 'Something went wrong. Please try again.';
  }
}
