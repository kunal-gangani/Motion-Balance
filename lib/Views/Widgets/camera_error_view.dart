import 'package:flutter/material.dart';

class CameraErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onSettings;

  const CameraErrorView({
    super.key,
    required this.message,
    required this.onRetry,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    final isPermissionIssue =
        message.toLowerCase().contains("permission");

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPermissionIssue
                  ? Icons.no_photography_outlined
                  : Icons.error_outline,
              color: Colors.white54,
              size: 60,
            ),
            const SizedBox(height: 18),
            Text(
              isPermissionIssue
                  ? "Permission Required"
                  : "Camera Error",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed:
                  isPermissionIssue ? onSettings : onRetry,
              child: Text(
                isPermissionIssue
                    ? "Open Settings"
                    : "Retry",
              ),
            ),
          ],
        ),
      ),
    );
  }
}
