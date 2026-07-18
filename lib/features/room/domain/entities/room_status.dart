enum RoomStatus {
  vacant('vacant'),
  partiallyOccupied('partially_occupied'),
  occupied('occupied'),
  inactive('inactive');

  final String databaseValue;
  const RoomStatus(this.databaseValue);

  static RoomStatus? fromDatabaseValue(String value) {
    for (final status in RoomStatus.values) {
      if (status.databaseValue == value) {
        return status;
      }
    }
    return null;
  }
}
