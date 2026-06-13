import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../screens/home_screen.dart';
import '../theme/app_theme.dart';

class SurayApp extends StatelessWidget {
  const SurayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Suray AIO',
      debugShowCheckedModeBanner: false,
      locale: const Locale('es'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es')],
      theme: AppTheme.theme,
      home: const HomeScreen(),
    );
  }
}
