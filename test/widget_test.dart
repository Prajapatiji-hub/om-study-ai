import 'package:flutter_test/flutter_test.dart';
import 'package:om_study_ai/main.dart';

void main() {
  testWidgets('missing Firebase configuration is explained safely',
      (tester) async {
    await tester.pumpWidget(const OmStudyApp(configured: false));

    expect(find.text('Firebase सेटअप बाकी है'), findsOneWidget);
    expect(find.textContaining('FB_API_KEY'), findsOneWidget);
  });
}
