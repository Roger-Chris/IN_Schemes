import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/auth_service.dart';

void main() {
  test('Google OAuth returns through the package-specific app link', () {
    final redirect = Uri.parse(AuthService.googleRedirectUrl);

    expect(redirect.scheme, 'com.inschemes.app');
    expect(redirect.host, 'login-callback');
    expect(redirect.path, '/');
  });
}
