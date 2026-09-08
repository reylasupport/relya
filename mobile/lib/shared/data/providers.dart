import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_env.dart';
import '../../services/cache/item_cache.dart';
import '../../services/ocr/mlkit_ocr_service.dart';
import '../../services/ocr/ocr_service.dart';
import '../../services/supabase/supabase_service.dart';
import 'cached_life_item_repository.dart';
import 'mock/mock_capture_repository.dart';
import 'mock/mock_life_item_repository.dart';
import 'mock/mock_simple_repositories.dart';
import 'repositories/assistant_repository.dart';
import 'repositories/capture_repository.dart';
import 'repositories/entity_repository.dart';
import 'repositories/feedback_repository.dart';
import 'repositories/life_item_repository.dart';
import 'repositories/profile_repository.dart';
import 'repositories/reminder_repository.dart';
import '../domain/user_profile.dart';
import 'supabase/supabase_capture_repository.dart';
import 'supabase/supabase_life_item_repository.dart';
import 'supabase/supabase_repositories.dart';

/// Set once at boot in [bootstrap]. Never available when running on fixtures.
final supabaseServiceProvider = Provider<SupabaseService>(
  (ref) => throw StateError('SupabaseService was not initialised'),
);

final ocrServiceProvider = Provider<OcrService>((ref) {
  if (AppEnv.useMockData) return const NoopOcrService();
  // defaultTargetPlatform rather than dart:io Platform, so the same code path
  // works in tests and in a browser preview.
  final onDevice =
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
  if (!kIsWeb && onDevice) {
    final service = MlKitOcrService();
    ref.onDispose(service.dispose);
    return service;
  }
  return const NoopOcrService();
});

/// One switch decides whether the whole app talks to Postgres or to fixtures.
/// Nothing above this line in the widget tree knows which one it got.
final lifeItemRepositoryProvider = Provider<LifeItemRepository>((ref) {
  if (AppEnv.useMockData) return MockLifeItemRepository();
  final supabase = ref.watch(supabaseServiceProvider);
  // The cache wraps the real repository rather than living inside it, so the
  // Postgres implementation stays a plain translation of the schema.
  return CachedLifeItemRepository(
    SupabaseLifeItemRepository(supabase),
    ref.watch(itemCacheProvider),
    () => supabase.userId,
  );
});

final captureRepositoryProvider = Provider<CaptureRepository>((ref) {
  if (AppEnv.useMockData) return MockCaptureRepository();
  return SupabaseCaptureRepository(
    ref.watch(supabaseServiceProvider),
    ref.watch(ocrServiceProvider),
  );
});

final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  if (AppEnv.useMockData) return MockReminderRepository();
  return SupabaseReminderRepository(ref.watch(supabaseServiceProvider));
});

final entityRepositoryProvider = Provider<EntityRepository>((ref) {
  if (AppEnv.useMockData) return MockEntityRepository();
  return SupabaseEntityRepository(ref.watch(supabaseServiceProvider));
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  if (AppEnv.useMockData) return MockProfileRepository();
  return SupabaseProfileRepository(ref.watch(supabaseServiceProvider));
});

final feedbackRepositoryProvider = Provider<FeedbackRepository>((ref) {
  if (AppEnv.useMockData) return MockFeedbackRepository();
  return SupabaseFeedbackRepository(ref.watch(supabaseServiceProvider));
});

final assistantRepositoryProvider = Provider<AssistantRepository>((ref) {
  if (AppEnv.useMockData) return MockAssistantRepository();
  return SupabaseAssistantRepository(ref.watch(supabaseServiceProvider));
});

/// The signed-in user profile. Watched by the Home header and the account
/// hub, so a plan change or a rename shows up in both without a manual
/// refresh.
final currentProfileProvider = FutureProvider<UserProfile?>(
  (ref) => ref.watch(profileRepositoryProvider).current(),
);
