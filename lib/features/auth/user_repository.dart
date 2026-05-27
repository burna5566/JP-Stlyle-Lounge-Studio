import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as appwrite_models;

import '../../core/appwrite/appwrite_client_factory.dart';
import '../../core/env/env.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.role,
    this.email,
    this.phone,
    this.avatarUrl,
  });

  final String id;
  final String name;
  final String role; // 'customer' | 'barber' | 'admin'
  final String? email;
  final String? phone;
  final String? avatarUrl;

  bool get isBarber => role == 'barber';
  bool get isAdmin => role == 'admin';
  bool get isCustomer => role == 'customer';

  factory AppUser.fromDocument(appwrite_models.Document doc) {
    final data = doc.data;
    return AppUser(
      id: doc.$id,
      name: (data['name'] as String?) ?? '',
      role: (data['role'] as String?) ?? 'customer',
      email: data['email'] as String?,
      phone: data['phone'] as String?,
      avatarUrl: data['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'role': role,
    if (email != null) 'email': email,
    if (phone != null) 'phone': phone,
    if (avatarUrl != null) 'avatar_url': avatarUrl,
  };
}

class UserRepository {
  UserRepository(this._factory);

  final AppwriteClientFactory _factory;

  Databases get _db => _factory.createDatabases();
  String get _databaseId => Env.appwriteDatabaseId;
  String get _collectionId => Env.usersCollectionId;

  /// Returns the [AppUser] profile for [userId], or null if not yet created.
  Future<AppUser?> getUser(String userId) async {
    try {
      final doc = await _db.getDocument(
        databaseId: _databaseId,
        collectionId: _collectionId,
        documentId: userId,
      );
      return AppUser.fromDocument(doc);
    } on AppwriteException catch (e) {
      if (e.code == 404) return null;
      rethrow;
    }
  }

  /// Creates the user profile document on first login.
  Future<AppUser> createUser({
    required String userId,
    required String name,
    String role = 'customer',
    String? email,
    String? phone,
  }) async {
    final doc = await _db.createDocument(
      databaseId: _databaseId,
      collectionId: _collectionId,
      documentId: userId,
      data: AppUser(
        id: userId,
        name: name,
        role: role,
        email: email,
        phone: phone,
      ).toJson(),
    );
    return AppUser.fromDocument(doc);
  }

  /// Updates mutable profile fields.
  Future<AppUser> updateProfile({
    required String userId,
    String? name,
    String? phone,
    String? avatarUrl,
  }) async {
    final data = <String, dynamic>{
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
    };
    final doc = await _db.updateDocument(
      databaseId: _databaseId,
      collectionId: _collectionId,
      documentId: userId,
      data: data,
    );
    return AppUser.fromDocument(doc);
  }
}
