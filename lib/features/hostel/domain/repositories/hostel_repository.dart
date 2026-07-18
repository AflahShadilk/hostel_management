import '../entities/hostel_entity.dart';

abstract interface class HostelRepository {
  Future<HostelEntity> createHostel(HostelEntity hostel);

  Future<HostelEntity?> getHostelById(int id);

  Future<HostelEntity?> getHostelByOwnerUserId(int ownerUserId);

  Future<bool> hasHostelForOwner(int ownerUserId);

  Future<void> updateHostel(HostelEntity hostel);
}
