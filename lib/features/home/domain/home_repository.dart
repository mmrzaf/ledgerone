import '../../../core/errors/result.dart';
import 'home_models.dart';

abstract interface class HomeRepository {
  /// Offline-first load of home content.
  Future<Result<HomeData>> load({bool forceRefresh = false});

  /// Optional: stream for real-time updates; can be a cached value + refresh.
  Stream<HomeData> watch();
}
