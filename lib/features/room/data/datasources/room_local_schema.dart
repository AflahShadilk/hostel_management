import 'package:sqflite/sqflite.dart';

class RoomLocalSchema {
  static const String tableRooms = 'rooms';
  static const String tableBeds = 'beds';

  static Future<void> createTables(Database db) async {
    await db.execute('''
      CREATE TABLE $tableRooms (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        hostel_id INTEGER NOT NULL,
        room_number TEXT NOT NULL,
        floor TEXT NOT NULL,
        room_type TEXT NOT NULL,
        number_of_beds INTEGER NOT NULL,
        monthly_rent REAL NOT NULL,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,

        UNIQUE(hostel_id, room_number),

        CHECK(number_of_beds > 0),
        CHECK(monthly_rent >= 0),

        CHECK(room_type IN (
          'single',
          'double',
          'triple',
          'dormitory',
          'other'
        )),

        CHECK(status IN (
          'vacant',
          'partially_occupied',
          'occupied',
          'inactive'
        )),

        FOREIGN KEY(hostel_id)
          REFERENCES hostels(id)
          ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableBeds (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        room_id INTEGER NOT NULL,
        bed_number TEXT NOT NULL,
        monthly_rent REAL NOT NULL,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,

        UNIQUE(room_id, bed_number),

        CHECK(monthly_rent >= 0),

        CHECK(status IN (
          'vacant',
          'occupied',
          'inactive'
        )),

        FOREIGN KEY(room_id)
          REFERENCES $tableRooms(id)
          ON DELETE CASCADE
      )
    ''');
  }

  static Future<void> migrateFromVersion7(Database db) async {
    // Add monthly_rent column to beds
    await db.execute('''
      ALTER TABLE $tableBeds ADD COLUMN monthly_rent REAL NOT NULL DEFAULT 0.0
    ''');
    
    // Populate monthly_rent from rooms table for existing data
    await db.execute('''
      UPDATE $tableBeds
      SET monthly_rent = (
        SELECT monthly_rent FROM $tableRooms
        WHERE $tableRooms.id = $tableBeds.room_id
      )
    ''');
  }
}
