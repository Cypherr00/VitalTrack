import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vital_track/core/providers/auth_provider.dart';
import 'package:vital_track/core/theme/theme_provider.dart';
import 'package:vital_track/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'isDarkMode': false});

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => AuthProvider()),
        ],
        child: const VitalTrackApp(),
      ),
    );
    expect(find.byType(VitalTrackApp), findsOneWidget);
  });
}
