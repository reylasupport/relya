import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/app_env.dart';

/// Thin wrapper around the Supabase client.
///
/// Every call made through it carries the signed-in user JWT, and every table
/// is protected by Row Level Security, so the client physically cannot read
/// another user rows even if a query is wrong.
class SupabaseService {
  SupabaseService(this._client);

  final SupabaseClient _client;

  static Future<SupabaseService> initialise() async {
    await Supabase.initialize(
      url: AppEnv.supabaseUrl,
      publishableKey: AppEnv.supabasePublishableKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
    return SupabaseService(Supabase.instance.client);
  }

  SupabaseClient get client => _client;

  GoTrueClient get auth => _client.auth;

  String? get userId => _client.auth.currentUser?.id;

  /// Throws if called without a session. Repositories rely on this so a bug
  /// can never silently write rows with a null owner.
  String get requireUserId {
    final id = userId;
    if (id == null) {
      throw StateError('No signed-in user');
    }
    return id;
  }

  SupabaseQueryBuilder table(String name) => _client.from(name);

  /// Invokes an Edge Function. All model calls go through here, never straight
  /// to a provider from the device.
  Future<T> invoke<T>(String function, {Map<String, dynamic>? body}) async {
    final response = await _client.functions.invoke(function, body: body);
    return response.data as T;
  }
}
