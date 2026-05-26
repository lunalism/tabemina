import 'package:flutter/foundation.dart';

/// Domain-layer user.
///
/// Mirrors just the fields the UI cares about — no Firebase types leak out
/// of the data layer. Repository implementations are responsible for
/// converting their auth-provider's user shape into this entity.
@immutable
class UserEntity {
  const UserEntity({
    required this.uid,
    this.displayName,
    this.email,
    this.photoUrl,
    this.createdAt,
  });

  final String uid;
  final String? displayName;
  final String? email;
  final String? photoUrl;
  final DateTime? createdAt;

  @override
  bool operator ==(Object other) =>
      other is UserEntity &&
      other.uid == uid &&
      other.displayName == displayName &&
      other.email == email &&
      other.photoUrl == photoUrl &&
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(uid, displayName, email, photoUrl, createdAt);
}
