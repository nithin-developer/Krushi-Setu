import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:krushi_setu/core/network/dio_client.dart';
import 'package:krushi_setu/features/auth/repositories/auth_repository.dart';

final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(dioClientProvider));
});
