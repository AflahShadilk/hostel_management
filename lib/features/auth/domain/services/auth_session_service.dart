import '../entities/user_role.dart';

abstract interface class AuthSessionService {
  // ── Legacy user-id session (kept for backward compat) ──────────────────────
  Future<void> saveSession(int userId);
  Future<int?> getUserId();
  Future<bool> hasSession();

  // ── Role persistence ────────────────────────────────────────────────────────
  /// Persists the selected role across launches (set once on role selection).
  Future<void> saveRole(UserRole role);

  /// Returns the stored role, or null if none has been selected yet.
  Future<UserRole?> getRole();

  /// Removes only the role (e.g. after logout to return to Role Selection).
  Future<void> clearRole();

  // ── Login-session flag ───────────────────────────────────────────────────────
  /// Marks the user as actively logged-in (set on successful password/PIN login).
  Future<void> markLoggedIn(int userId);

  /// Returns true only when `markLoggedIn` has been called and not cleared.
  Future<bool> isLoggedIn();

  /// Removes the login flag (e.g. "Forgot PIN?" → back to Login).
  Future<void> clearLoginSession();

  // ── Full logout ──────────────────────────────────────────────────────────────
  /// Clears ALL auth state: userId, role, login flag.
  Future<void> clearAll();

  // ── Legacy clear (kept for existing call sites) ─────────────────────────────
  Future<void> clearSession();
}
