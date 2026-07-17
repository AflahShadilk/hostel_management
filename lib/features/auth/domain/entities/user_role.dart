enum UserRole {
  owner,
  manager;

  String get databaseValue => switch (this) {
        UserRole.owner => 'owner',
        UserRole.manager => 'manager',
      };

  /// Returns null for unrecognised values rather than silently mapping to a
  /// default role, so callers can decide how to handle corrupt stored data.
  static UserRole? fromDatabaseValue(String value) => switch (value) {
        'owner' => UserRole.owner,
        'manager' => UserRole.manager,
        _ => null,
      };
}
