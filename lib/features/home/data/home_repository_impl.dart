import 'package:flutter/cupertino.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/errors/result.dart';
import '../../../core/runtime/cancellation_token.dart';
import '../../../core/runtime/retry_helper.dart';
import '../domain/home_models.dart';
import '../domain/home_repository.dart';
import '../domain/home_source.dart';

class HomeRepositoryImpl implements HomeRepository {
  final HomeRemoteDataSource _remote;
  final HomeLocalDataSource _local;

  HomeRepositoryImpl({
    required HomeRemoteDataSource remote,
    required HomeLocalDataSource local,
  }) : _remote = remote,
       _local = local;

  @override
  Future<Result<HomeData>> load({bool forceRefresh = false}) async {
    final cached = await _local.get();
    final HomeData? lastKnownGood = cached?.data;

    final result = await RetryHelper.executeWithPolicy<HomeData>(
      operation: () => _remote.fetchHomeData(),
      category: ErrorCategory.timeout,
      cancellationToken: CancellationToken.none,
      onRetry: (attempt, error) {
        debugPrint('HomeRepository: retry $attempt after ${error.category}');
      },
    );

    if (result.isSuccess) {
      final fresh = result.data!;
      await _local.set(fresh);
      return Success(fresh);
    }

    if (lastKnownGood != null) {
      return Success(lastKnownGood);
    }

    return Failure(result.error!);
  }

  @override
  Stream<HomeData> watch() async* {
    final cached = await _local.get();
    if (cached != null) {
      yield cached.data;
    }
  }
}
