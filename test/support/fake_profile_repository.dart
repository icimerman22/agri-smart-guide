import 'package:agri_smart_guide/features/profile/domain/profile_repository.dart';
import 'package:agri_smart_guide/shared/models/user_profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FakeProfileRepository implements ProfileRepository {
  final Map<String, UserProfile> profiles = {};

  @override
  Future<UserProfile> loadProfile(String uid) async =>
      profiles[uid] ?? defaultUserProfile(uid, Timestamp(0, 0));

  @override
  Future<UserProfile> saveProfile(UserProfile profile) async =>
      profiles[profile.id] = profile;
}
