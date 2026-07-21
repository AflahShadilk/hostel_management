import '../entities/rent_collection_item_entity.dart';

abstract class RentCollectionRepository {
  /// Retrieves all active rent collection items, combining rent records with their stay details.
  Future<List<RentCollectionItemEntity>> getRentCollectionItems();
}
