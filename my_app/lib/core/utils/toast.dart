import 'package:flutter/material.dart';

const _kPurple = Color(0xFF6264A7);
const _kError = Color(0xFFDC2626);
const _kWarning = Color(0xFFD97706);

enum ToastType { success, error, warning, info }

void showAppToast(
  BuildContext context, {
  required String message,
  ToastType type = ToastType.success,
  Color? color,
  IconData? icon,
  Duration duration = const Duration(seconds: 2),
  SnackBarAction? action,
}) {
  final bg = color ??
      switch (type) {
        ToastType.success => _kPurple,
        ToastType.error => _kError,
        ToastType.warning => _kWarning,
        ToastType.info => _kPurple,
      };

  final ic = icon ??
      switch (type) {
        ToastType.success => Icons.check_rounded,
        ToastType.error => Icons.error_outline_rounded,
        ToastType.warning => Icons.warning_amber_rounded,
        ToastType.info => Icons.info_outline_rounded,
      };

  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(32, 0, 32, 88),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        backgroundColor: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 8,
        duration: duration,
        action: action,
        content: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(ic, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
}
