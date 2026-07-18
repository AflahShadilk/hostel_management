import '../entities/bed_entity.dart';
import '../entities/bed_status.dart';

abstract interface class BedRepository {
  Future<BedEntity> createBed(BedEntity bed);
  Future<void> createBeds(List<BedEntity> beds);
  Future<BedEntity?> getBedById(int id);
  Future<List<BedEntity>> getBedsByRoomId(int roomId);
  Future<List<BedEntity>> getVacantBedsByRoomId(int roomId);
  Future<bool> bedNumberExists({
    required int roomId,
    required String bedNumber,
    int? excludeBedId,
  });
  Future<void> updateBed(BedEntity bed);
  Future<void> deleteBed(int id);
  Future<int> countBedsByRoomId(int roomId);
  Future<int> countBedsByStatus({
    required int roomId,
    required BedStatus status,
  });
}
