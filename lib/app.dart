import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'config/theme_config.dart';
import 'config/routes.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'presentation/screens/splash/splash_screen.dart';

class CollegeResourceHubApp extends StatelessWidget {
  const CollegeResourceHubApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'College Resource Hub',
          debugShowCheckedModeBanner: false,
          theme: ThemeConfig.lightTheme,
          darkTheme: ThemeConfig.darkTheme,
          themeMode: themeProvider.themeMode,
          onGenerateRoute: AppRoutes.generateRoute,
          // ✅ REMOVED home and initialRoute conflict - only using onGenerateRoute
          initialRoute: AppRoutes.splash,
        );
      },
    );
  }
}