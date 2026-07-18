enum BedStatus {
  vacant('vacant'),
  occupied('occupied'),
  inactive('inactive');

  final String databaseValue;
  const BedStatus(this.databaseValue);

  static BedStatus? fromDatabaseValue(String value) {
    for (final status in BedStatus.values) {
      if (status.databaseValue == value) {
        return status;
      }
    }
    return null;
  }
}
