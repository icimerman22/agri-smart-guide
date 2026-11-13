import 'package:agri_smart_guide/features/profile/domain/profile_repository.dart';
import 'package:agri_smart_guide/shared/models/user_profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FakeProfileRepository implements ProfileRepository {
  final Map<String, UserProfile> profiles = {};

  ProfileException? loadError;
  ProfileException? saveError;
  int loadCalls = 0;
  int saveCalls = 0;

  @override
  Future<UserProfile> loadProfile(String uid) async {
    loadCalls++;
    if (loadError != null) throw loadError!;
    return profiles[uid] ?? defaultUserProfile(uid, Timestamp(0, 0));
  }

  @override
  Future<UserProfile> saveProfile(UserProfile profile) async {
    saveCalls++;
    if (saveError != null) throw saveError!;
    return profiles[profile.id] = profile;
  }
}
