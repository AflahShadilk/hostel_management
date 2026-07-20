import '../entities/search_filter.dart';
import '../entities/search_result_entity.dart';

abstract interface class SearchRepository {
  Future<List<SearchResultEntity>> search({
    required String query,
    required SearchFilter filter,
  });
}
