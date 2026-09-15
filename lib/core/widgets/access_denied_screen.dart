import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AccessDeniedScreen extends StatelessWidget {
  final String? routeName;

  const AccessDeniedScreen({super.key, this.routeName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.2)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.lock_rounded,
                        color: Color(0xFFEF4444),
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Access Denied',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      routeName != null
                          ? 'You do not have permission to access the "$routeName" module.'
                          : 'You do not have required authorization to perform this operation.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    FilledButton.icon(
                      onPressed: () => context.go('/'),
                      icon: const Icon(Icons.dashboard_rounded, size: 18),
                      label: const Text('Back to Dashboard'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
