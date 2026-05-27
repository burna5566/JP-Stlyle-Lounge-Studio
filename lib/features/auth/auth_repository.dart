import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as appwrite_models;

import '../../core/appwrite/appwrite_client_factory.dart';
import '../../core/appwrite/appwrite_config.dart';

class AuthRepository {
  AuthRepository(this._factory);

  final AppwriteClientFactory _factory;

  Account get _account => _factory.createAccount();

  // ── Session ────────────────────────────────────────────────────────────────

  Future<appwrite_models.User?> currentUser() async {
    try {
      return await _account.get();
    } on AppwriteException {
      return null;
    }
  }

  Future<void> signOut() async {
    await _account.deleteSession(sessionId: 'current');
  }

  // ── Email + Password ───────────────────────────────────────────────────────

  Future<appwrite_models.User> createEmailAccount({
    required String name,
    required String email,
    required String password,
  }) async {
    return _account.create(
      userId: ID.unique(),
      email: email,
      password: password,
      name: name,
    );
  }

  Future<appwrite_models.Session> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return _account.createEmailPasswordSession(
      email: email,
      password: password,
    );
  }

  // ── Phone OTP ──────────────────────────────────────────────────────────────

  /// Sends an OTP to [phone] (E.164 format, e.g. +233XXXXXXXXX).
  /// Returns the userId needed for [verifyOtp].
  Future<String> sendPhoneOtp(String phone) async {
    final token = await _account.createPhoneToken(
      userId: ID.unique(),
      phone: phone,
    );
    return token.userId;
  }

  /// Verifies the OTP and returns the session.
  Future<appwrite_models.Session> verifyOtp({
    required String userId,
    required String otp,
  }) async {
    return _account.createSession(userId: userId, secret: otp);
  }

  // ── Google OAuth ───────────────────────────────────────────────────────────

  /// Opens the Appwrite OAuth flow for Google.
  /// On mobile this launches a browser; the deep link brings the user back.
  /// TODO: Fix OAuthProvider import when appwrite SDK updated to support it.
  Future<void> signInWithGoogle({
    required String successUrl,
    required String failureUrl,
  }) async {
    // Placeholder: Google OAuth to be implemented after SDK upgrade
    // For now, OAuth is skipped in login_screen
    throw UnimplementedError(
      'Google OAuth requires appwrite SDK update. Use phone OTP or email instead.',
    );
    // await _account.createOAuth2Session(
    //   provider: 'google',
    //   success: successUrl,
    //   failure: failureUrl,
    // );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static AppwriteClientFactory factoryFromEnv() {
    return AppwriteClientFactory(AppwriteConfig.fromEnv());
  }
}
