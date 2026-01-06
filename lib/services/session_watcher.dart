import 'package:flutter/widgets.dart';
import 'auth_service.dart';

class SessionWatcher with WidgetsBindingObserver {
  final AuthService _authService;

  SessionWatcher(this._authService);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      final isExpired = await _authService.isTokenExpired();
      if (isExpired) {
        await _authService.forceLogout();
      }
    }
  }
}
