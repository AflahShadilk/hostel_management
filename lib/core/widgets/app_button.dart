import 'package:flutter/material.dart';

import 'app_button_loading.dart';

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? icon;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isFullWidth = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final button = ElevatedButton.icon(
      // Keeps the button visually active (non-disabled) while loading so the
      // primary background colour is preserved around the progress indicator.
      onPressed: isLoading ? () {} : onPressed,
      icon: isLoading
          ? AppButtonLoading(
              color: Theme.of(context).colorScheme.onPrimary,
            )
          : icon == null
              ? const SizedBox.shrink()
              : Icon(icon, size: 18),
      label: Text(label),
    );

    if (isFullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }

    return button;
  }
}
