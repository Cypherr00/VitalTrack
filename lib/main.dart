import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/main/screens/main_layout.dart';

void main() async {
  // Required for SharedPreferences and plugins to work before runApp
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const VitalTrackApp(),
    ),
  );
}

class VitalTrackApp extends StatelessWidget {
  const VitalTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        // Wait for SharedPreferences to load before rendering
        if (!themeProvider.isLoaded) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final isDark = themeProvider.isDarkMode;

        // Sync Android status bar style with theme
        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        ));

        return MaterialApp(
          title: 'Vital Track',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          home: const MainLayout(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
