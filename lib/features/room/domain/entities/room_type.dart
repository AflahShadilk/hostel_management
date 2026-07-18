enum RoomType {
  single('single'),
  double('double'),
  triple('triple'),
  dormitory('dormitory'),
  other('other');

  final String databaseValue;
  const RoomType(this.databaseValue);

  static RoomType? fromDatabaseValue(String value) {
    for (final type in RoomType.values) {
      if (type.databaseValue == value) {
        return type;
      }
    }
    return null;
  }
}
