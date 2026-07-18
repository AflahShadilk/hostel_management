import 'package:flutter/material.dart';

/// A small loading indicator designed specifically for buttons.
class AppButtonLoading extends StatelessWidget {
  final Color? color;
  final double size;

  const AppButtonLoading({
    super.key,
    this.color,
    this.size = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? Colors.white,
        ),
      ),
    );
  }
}
