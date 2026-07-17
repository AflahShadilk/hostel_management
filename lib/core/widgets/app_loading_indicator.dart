import 'package:flutter/material.dart';

import '../constants/app_spacing.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Full mode: centred, animated hostel-icon pulse for page-level loading.
/// Compact mode: small [CircularProgressIndicator] for inline/overlay use.
class AppLoadingIndicator extends StatefulWidget {
  final String? message;
  final bool compact;

  const AppLoadingIndicator({
    super.key,
    this.message,
    this.compact = false,
  });

  @override
  State<AppLoadingIndicator> createState() => _AppLoadingIndicatorState();
}

class _AppLoadingIndicatorState extends State<AppLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Both animations share the same curved parent so they stay in sync.
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _scale = Tween<double>(begin: 0.92, end: 1.0).animate(curved);
    _opacity = Tween<double>(begin: 0.55, end: 1.0).animate(curved);

    // Ticker is created but not started for compact mode, keeping overhead low.
    if (!widget.compact) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      return Semantics(
        label: 'Loading',
        child: const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      );
    }

    return Semantics(
      label: widget.message ?? 'Loading',
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // FadeTransition + ScaleTransition avoid per-frame widget rebuilds
            // by operating directly on the render object.
            FadeTransition(
              opacity: _opacity,
              child: ScaleTransition(
                scale: _scale,
                child: const Icon(
                  Icons.apartment_rounded,
                  size: 56,
                  color: AppColors.primary,
                ),
              ),
            ),
            if (widget.message != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                widget.message!,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
