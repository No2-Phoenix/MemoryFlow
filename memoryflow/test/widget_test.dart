import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memoryflow/app.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const ProviderScope(child: MemoryFlowApp()));

    await tester.pump();
    expect(find.text('MemoryFlow'), findsOneWidget);
  });
}
