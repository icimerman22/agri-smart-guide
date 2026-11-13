import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/models/user_profile.dart';
import '../domain/profile_repository.dart';

class FirestoreProfileRepository implements ProfileRepository {
  FirestoreProfileRepository({
    FirebaseFirestore? firestore,
    Timestamp Function()? clock,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _clock = clock ?? Timestamp.now;

  final FirebaseFirestore _firestore;
  final Timestamp Function() _clock;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _firestore.collection('users').doc(uid);

  @override
  Future<UserProfile> loadProfile(String uid) => _translateErrors(() async {
    final snapshot = await _userDoc(uid).get();
    if (!snapshot.exists) return defaultUserProfile(uid, _clock());
    return UserProfile.fromFirestore(snapshot);
  });

  @override
  Future<UserProfile> saveProfile(UserProfile profile) =>
      _translateErrors(() async {
        // set() writes the whole document because the rules (valid_users)
        // require every field on both create and update.
        final saved = profile.copyWith(updatedAt: _clock());
        await _userDoc(profile.id).set(saved.toMap());
        return saved;
      });

  Future<T> _translateErrors<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FirebaseException catch (error) {
      throw ProfileException(error.code, message: error.message);
    } on FormatException catch (error) {
      throw ProfileException('invalid-data', message: error.message);
    }
  }
}
