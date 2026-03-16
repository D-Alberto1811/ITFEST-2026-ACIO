import 'package:flutter_test/flutter_test.dart';
import 'package:fitlingo/main.dart';

void main() {
  test('FitLingoApp can be created', () {
    const app = FitLingoApp(isLoggedIn: false);
    expect(app, isA<FitLingoApp>());
  });
}