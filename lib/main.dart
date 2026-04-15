import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motion_balance/MotionBalanceApp/motion_balance_app.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MotionBalanceApp(),
    ),
  );
}
