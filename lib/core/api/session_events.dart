import 'dart:async';

/// Lets the API layer announce a dead session without depending on the auth
/// feature. `AuthNotifier` listens and drops the user; the router then
/// redirects to the login screen.
class SessionEvents {
  final StreamController<void> _expired = StreamController<void>.broadcast();

  Stream<void> get expired => _expired.stream;

  void notifyExpired() {
    if (!_expired.isClosed) _expired.add(null);
  }

  Future<void> dispose() => _expired.close();
}
