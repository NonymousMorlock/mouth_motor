import 'package:flutter_test/flutter_test.dart';
import 'package:motor_mouth/app/app.dart';
import 'package:motor_mouth/src/tts/presentation/views/home_view.dart';

void main() {
  group('App', () {
    testWidgets('renders HomeView', (tester) async {
      await tester.pumpWidget(const App());
      expect(find.byType(HomeView), findsOneWidget);
    });
  });
}
