import 'package:flutter/material.dart';

import 'glass_button.dart';
import 'gradient_background.dart';

Future<bool> showGlassConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmText,
  String cancelText = '取消',
  Color? accentColor,
  IconData icon = Icons.warning_amber_rounded,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.42),
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: GlassContainer(
          borderRadius: 32,
          tintColor: accentColor ?? Colors.white,
          opacity: 0.12,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GlassContainer(
                    borderRadius: 18,
                    tintColor: accentColor ?? Colors.white,
                    opacity: 0.18,
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      icon,
                      color: Colors.white.withValues(alpha: 0.92),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(message, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: GlassButton(
                      text: cancelText,
                      expand: true,
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GlassButton(
                      text: confirmText,
                      expand: true,
                      isActive: true,
                      highlightColor: accentColor ?? const Color(0xFFFF6B6B),
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );

  return confirmed ?? false;
}
