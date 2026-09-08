import '../../domain/user_preferences.dart';
import '../../domain/user_profile.dart';

abstract interface class ProfileRepository {
  Future<UserProfile?> current();

  Future<UserProfile> update(UserProfile profile);

  Future<UserPreferences> preferences();

  Future<UserPreferences> savePreferences(UserPreferences preferences);

  /// Removes every row and every stored file for this user, then the account
  /// itself (spec section 72). Irreversible, and always behind a confirmation.
  Future<void> deleteAccount();

  /// Produces a JSON bundle of everything we hold (spec section 73).
  Future<String> exportData();
}
