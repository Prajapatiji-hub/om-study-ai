import 'package:flutter_test/flutter_test.dart';
import 'package:om_study_ai/screens/dashboard.dart';

void main() {
  test('editable AI Study Memory is available from the dashboard', () {
    final memoryModule = kModules.singleWhere(
      (module) => module.title == 'मेरी AI मेमोरी',
    );

    // ProfileScreen contains the student's editable private-memory controls.
    expect(memoryModule.ready, isTrue);
  });
}
