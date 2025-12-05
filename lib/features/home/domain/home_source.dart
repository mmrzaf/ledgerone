import '../../../core/contracts/cache_contract.dart';
import 'home_models.dart';

abstract interface class HomeLocalDataSource {
  Future<CachedData<HomeData>?> get();

  Future<void> set(HomeData data);

  Future<void> clear();
}

abstract interface class HomeRemoteDataSource {
  Future<HomeData> fetchHomeData();
}
