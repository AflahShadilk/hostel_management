import 'package:flutter/material.dart';

import '../../constants/app_spacing.dart';

/// A generic export action sheet with callback-only document actions.
class ExportPdfBottomSheet extends StatelessWidget {
  const ExportPdfBottomSheet({
    super.key,
    required this.onExportPdf,
    required this.onSharePdf,
    required this.onSavePdf,
    this.onCancel,
  });

  final VoidCallback onExportPdf;
  final VoidCallback onSharePdf;
  final VoidCallback onSavePdf;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Export',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Divider(),
            _ExportActionTile(
              icon: Icons.picture_as_pdf_outlined,
              title: 'Export PDF',
              subtitle: 'Generate printable PDF',
              onTap: onExportPdf,
            ),
            _ExportActionTile(
              icon: Icons.share_outlined,
              title: 'Share PDF',
              subtitle: 'Generate and share',
              onTap: onSharePdf,
            ),
            _ExportActionTile(
              icon: Icons.save_alt_outlined,
              title: 'Save PDF',
              subtitle: 'Generate and save',
              onTap: onSavePdf,
            ),
            const Divider(),
            TextButton(
              onPressed: onCancel ?? () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExportActionTile extends StatelessWidget {
  const _ExportActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: colors.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: colors.onPrimaryContainer),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }
}
