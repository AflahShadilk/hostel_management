import '../../../../core/database/app_database.dart';
import '../../domain/entities/hostel_entity.dart';
import '../../domain/repositories/hostel_repository.dart';
import '../models/hostel_model.dart';

class HostelRepositoryImpl implements HostelRepository {
  final AppDatabase _appDatabase;

  const HostelRepositoryImpl(this._appDatabase);

  @override
  Future<HostelEntity> createHostel(HostelEntity hostel) async {
    final db = await _appDatabase.database;

    final normalised = _normalise(hostel);

    final id = await db.insert('hostels', HostelModel.toMap(normalised));

    return HostelEntity(
      id: id,
      name: normalised.name,
      logoPath: normalised.logoPath,
      address: normalised.address,
      phone: normalised.phone,
      email: normalised.email,
      ownerName: normalised.ownerName,
      ownerUserId: normalised.ownerUserId,
      createdAt: normalised.createdAt,
      updatedAt: normalised.updatedAt,
    );
  }

  @override
  Future<HostelEntity?> getHostelById(int id) async {
    final db = await _appDatabase.database;
    final results = await db.query(
      'hostels',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return HostelModel.fromMap(results.first);
  }

  @override
  Future<HostelEntity?> getHostelByOwnerUserId(int ownerUserId) async {
    final db = await _appDatabase.database;
    final results = await db.query(
      'hostels',
      where: 'owner_user_id = ?',
      whereArgs: [ownerUserId],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return HostelModel.fromMap(results.first);
  }

  @override
  Future<bool> hasHostelForOwner(int ownerUserId) async {
    final db = await _appDatabase.database;
    final results = await db.query(
      'hostels',
      columns: ['1'],
      where: 'owner_user_id = ?',
      whereArgs: [ownerUserId],
      limit: 1,
    );
    return results.isNotEmpty;
  }

  @override
  Future<void> updateHostel(HostelEntity hostel) async {
    if (hostel.id == null) {
      throw ArgumentError('Cannot update a hostel without a valid id.');
    }

    final db = await _appDatabase.database;
    final normalised = _normalise(hostel);

    final rowsAffected = await db.update(
      'hostels',
      HostelModel.toMap(normalised),
      where: 'id = ?',
      whereArgs: [normalised.id],
    );

    if (rowsAffected == 0) {
      throw StateError('No hostel row found with id ${hostel.id} to update.');
    }
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  /// Normalises string fields at the persistence boundary.
  HostelEntity _normalise(HostelEntity hostel) {
    return HostelEntity(
      id: hostel.id,
      name: hostel.name.trim(),
      logoPath: hostel.logoPath,
      address: hostel.address.trim(),
      phone: hostel.phone.trim(),
      email: hostel.email.trim().toLowerCase(),
      ownerName: hostel.ownerName.trim(),
      ownerUserId: hostel.ownerUserId,
      createdAt: hostel.createdAt,
      updatedAt: hostel.updatedAt,
    );
  }
}
