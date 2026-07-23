import 'package:flutter/material.dart';

import '../constants/app_spacing.dart';
import '../widgets/app_dashboard_ui.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(title: const Text('About')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: <Widget>[
            AppDashboardCard(
              backgroundColor: colors.primaryContainer,
              child: Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.apartment_rounded,
                      color: colors.primary,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Hostel Management System',
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: colors.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'A focused, offline-first workspace',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colors.onPrimaryContainer
                                .withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _AboutSection(
              title: 'App Information',
              icon: Icons.info_outline_rounded,
              child: const Column(
                children: <Widget>[
                  _AboutRow(label: 'Version', value: '1.0.0'),
                  _AboutRow(label: 'Experience', value: 'Offline First'),
                  _AboutRow(label: 'Built with', value: 'Flutter'),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _AboutSection(
              title: 'Features',
              icon: Icons.auto_awesome_outlined,
              child: const Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: <Widget>[
                  _FeatureChip('Dashboard'),
                  _FeatureChip('Room Management'),
                  _FeatureChip('Bed Management'),
                  _FeatureChip('Tenant Management'),
                  _FeatureChip('Stay Records'),
                  _FeatureChip('Checkout'),
                  _FeatureChip('Financial Management'),
                  _FeatureChip('Hostel Profile'),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _AboutSection(
              title: 'Technology',
              icon: Icons.memory_outlined,
              child: const Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: <Widget>[
                  _FeatureChip('Flutter'),
                  _FeatureChip('SQLite'),
                  _FeatureChip('Material 3'),
                  _FeatureChip('Clean Architecture'),
                  _FeatureChip('Cubit'),
                  _FeatureChip('Repository Pattern'),
                  _FeatureChip('Offline First'),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const _AboutSection(
              title: 'Developer',
              icon: Icons.person_outline_rounded,
              child: Column(
                children: <Widget>[
                  _AboutRow(label: 'Developed by', value: 'Aflah Shadil K'),
                  _AboutRow(label: 'Role', value: 'Flutter Developer'),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              '\u00A9 2026 Hostel Management System',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) => AppSectionCard(
        title: title,
        icon: icon,
        child: child,
      );
}

class _AboutRow extends StatelessWidget {
  const _AboutRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Chip(
      avatar: Icon(Icons.check_rounded, size: 16, color: colors.primary),
      label: Text(label),
      side: BorderSide(color: colors.outlineVariant),
      backgroundColor: colors.surfaceContainerLowest,
      visualDensity: VisualDensity.compact,
    );
  }
}
