import 'package:flutter/material.dart';
import 'package:motion_balance/Core/Theme/app_theme.dart';
import 'package:motion_balance/Views/SplashScreen/splash_screen.dart';

class MotionBalanceApp extends StatelessWidget {
  const MotionBalanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MotionBalance',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}
