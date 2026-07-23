import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/pdf/widgets/export_pdf_bottom_sheet.dart';
import '../../../../core/widgets/app_dashboard_ui.dart';
import '../../../hostel/presentation/cubit/hostel_cubit.dart';
import '../../domain/entities/profit_loss_entity.dart';
import '../cubit/profit_loss_cubit.dart';
import '../cubit/profit_loss_state.dart';
import '../cubit/reports_date_filter.dart';
import '../services/profit_loss_pdf_export_service.dart';

class ProfitLossPage extends StatefulWidget {
  const ProfitLossPage({super.key});

  @override
  State<ProfitLossPage> createState() => _ProfitLossPageState();
}

class _ProfitLossPageState extends State<ProfitLossPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context
            .read<ProfitLossCubit>()
            .loadWithFilter(ReportsDateFilter.thisMonth);
      }
    });
  }

  Future<void> _pickCustomRange() async {
    final cubit = context.read<ProfitLossCubit>();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2099),
    );
    if (range != null && mounted) {
      await cubit.loadWithCustomRange(
        range.start,
        DateTime(range.end.year, range.end.month, range.end.day, 23, 59, 59),
      );
    }
  }

  void _showExportSheet(ProfitLossState state) {
    if (state.data == null) return;

    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => ExportPdfBottomSheet(
        onExportPdf: () {
          Navigator.pop(sheetContext);
          _previewPdf(state);
        },
        onSharePdf: () {
          Navigator.pop(sheetContext);
          _sharePdf(state);
        },
        onSavePdf: () {
          Navigator.pop(sheetContext);
          _savePdf(state);
        },
      ),
    );
  }

  Future<void> _previewPdf(ProfitLossState state) => _runExport(
        (service, hostelName, logoPath) => service.preview(
          state: state,
          hostelName: hostelName,
          logoPath: logoPath,
        ),
      );

  Future<void> _sharePdf(ProfitLossState state) => _runExport(
        (service, hostelName, logoPath) => service.share(
          state: state,
          hostelName: hostelName,
          logoPath: logoPath,
        ),
      );

  Future<void> _savePdf(ProfitLossState state) => _runExport(
        (service, hostelName, logoPath) async {
          await service.save(
            state: state,
            hostelName: hostelName,
            logoPath: logoPath,
          );
        },
        successMessage: 'Report saved to Hostel Management/Reports.',
      );

  Future<void> _runExport(
    Future<void> Function(
      ProfitLossPdfExportService service,
      String hostelName,
      String? logoPath,
    )
        action, {
    String? successMessage,
  }) async {
    final hostel = context.read<HostelCubit>().state.hostel;
    try {
      await action(
        getIt<ProfitLossPdfExportService>(),
        hostel?.name ?? 'Hostel Management',
        hostel?.logoPath,
      );
      if (!mounted || successMessage == null) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to export the report.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          bottom: false,
          child: BlocBuilder<ProfitLossCubit, ProfitLossState>(
            builder: (context, state) => CustomScrollView(
              slivers: <Widget>[
                SliverToBoxAdapter(child: _Header(state: state)),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.xl,
                  ),
                  sliver: SliverToBoxAdapter(child: _body(state)),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _body(ProfitLossState state) {
    if (state.isLoading && state.data == null) {
      return const _LoadingContent();
    }
    if (state.error != null && state.data == null) {
      return _ErrorContent(error: state.error!);
    }
    if (state.data == null) return const _EmptyContent();
    return _ReportContent(data: state.data!);
  }

  String _filterLabel(ProfitLossState state, ReportsDateFilter filter) {
    if (filter == ReportsDateFilter.custom && state.customFrom != null) {
      return '${state.customFrom!.day}/${state.customFrom!.month} – '
          '${state.customTo!.day}/${state.customTo!.month}';
    }
    return filter.label;
  }

  Widget _filterBar(ProfitLossState state) {
    const filters = <ReportsDateFilter>[
      ReportsDateFilter.today,
      ReportsDateFilter.thisWeek,
      ReportsDateFilter.thisMonth,
      ReportsDateFilter.thisYear,
      ReportsDateFilter.custom,
    ];
    return SizedBox(
      height: 54,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final filter = filters[index];
          return AppFilterChip(
            label: _filterLabel(state, filter),
            selected: state.activeFilter == filter,
            onSelected: (_) => filter == ReportsDateFilter.custom
                ? _pickCustomRange()
                : context.read<ProfitLossCubit>().loadWithFilter(filter),
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.state});

  final ProfitLossState state;

  @override
  Widget build(BuildContext context) {
    final page = context.findAncestorStateOfType<_ProfitLossPageState>()!;
    final colors = Theme.of(context).colorScheme;
    return Container(
      decoration: const BoxDecoration(gradient: AppGradients.primary),
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: colors.onPrimary.withValues(alpha: .16),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.bar_chart_rounded, color: colors.onPrimary),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Profit & Loss',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: colors.onPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      Text(
                        'Financial overview of the hostel',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colors.onPrimary.withValues(alpha: .82),
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Export report',
                  onPressed:
                      state.data == null ? null : () => page._showExportSheet(state),
                  icon: Icon(
                    Icons.file_download_outlined,
                    color: colors.onPrimary,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: colors.surface.withValues(alpha: .14),
            child: page._filterBar(state),
          ),
        ],
      ),
    );
  }
}

class _ReportContent extends StatelessWidget {
  const _ReportContent({required this.data});

  final ProfitLossEntity data;

  String money(double value) => '₹${value.abs().toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) {
    final profit = data.isProfit;
    final accent = profit ? const Color(0xFF22C55E) : const Color(0xFFFB7185);
    return Column(
      children: <Widget>[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: profit
                  ? const <Color>[Color(0xFF166534), Color(0xFF15803D)]
                  : const <Color>[Color(0xFF991B1B), Color(0xFFB91C1C)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Chip(
                    avatar: Icon(
                      profit ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                      color: accent,
                      size: 18,
                    ),
                    label: Text(profit ? 'Profit' : 'Loss'),
                  ),
                  const Spacer(),
                  Icon(Icons.account_balance_wallet_rounded,
                      color: Colors.white.withValues(alpha: .6)),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Net Profit', style: TextStyle(color: Colors.white.withValues(alpha: .76))),
              Text(
                '${profit ? '' : '−'}${money(data.netProfit)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: <Widget>[
                  _HeroMetric('Revenue', money(data.totalRevenue)),
                  _HeroMetric('Expenses', money(data.totalExpenses)),
                  _HeroMetric('Margin', '${data.profitMargin.toStringAsFixed(1)}%'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            final count = constraints.maxWidth >= 700 ? 4 : 2;
            return GridView.count(
              crossAxisCount: count,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
              childAspectRatio: constraints.maxWidth < 360 ? .92 : 1.05,
              children: <Widget>[
                AppStatTile(icon: Icons.payments_rounded, iconColor: const Color(0xFF1976D2), iconBackground: const Color(0xFFE3F2FD), label: 'Total Revenue', value: money(data.totalRevenue), subtitle: 'Collected payments'),
                AppStatTile(icon: Icons.receipt_long_rounded, iconColor: const Color(0xFFC62828), iconBackground: const Color(0xFFFFEBEE), label: 'Total Expenses', value: money(data.totalExpenses), subtitle: 'Operational costs'),
                AppStatTile(icon: profit ? Icons.trending_up_rounded : Icons.trending_down_rounded, iconColor: accent, iconBackground: accent.withValues(alpha: .12), label: 'Net Profit', value: '${profit ? '' : '−'}${money(data.netProfit)}', subtitle: profit ? 'Profitable period' : 'Loss period'),
                AppStatTile(icon: Icons.donut_large_rounded, iconColor: const Color(0xFF6A1B9A), iconBackground: const Color(0xFFF3E5F5), label: 'Profit Margin', value: '${data.profitMargin.toStringAsFixed(1)}%', subtitle: 'Revenue efficiency'),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.md),
        AppSectionCard(
          title: 'Revenue Breakdown',
          icon: Icons.pie_chart_outline_rounded,
          child: Column(children: <Widget>[
            AppProgressRow(label: 'Rent', amount: money(data.rentRevenue), percentage: data.totalRevenue == 0 ? 0 : data.rentRevenue / data.totalRevenue, color: const Color(0xFF1976D2)),
            const SizedBox(height: AppSpacing.md),
            AppProgressRow(label: 'Damage Charges', amount: money(data.damageChargeRevenue), percentage: data.totalRevenue == 0 ? 0 : data.damageChargeRevenue / data.totalRevenue, color: const Color(0xFFE65100)),
            const SizedBox(height: AppSpacing.md),
            AppProgressRow(label: 'Other Income', amount: money(data.otherRevenue), percentage: data.totalRevenue == 0 ? 0 : data.otherRevenue / data.totalRevenue, color: const Color(0xFF388E3C)),
          ]),
        ),
        const SizedBox(height: AppSpacing.md),
        AppSectionCard(
          title: 'Quick Insights',
          icon: Icons.lightbulb_outline_rounded,
          child: Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: <Widget>[
            _Insight('Best Revenue', data.rentRevenue >= data.damageChargeRevenue ? 'Rent' : 'Damage Charges'),
            _Insight('Margin Health', data.profitMargin >= 20 ? 'Healthy' : profit ? 'Watch closely' : 'Loss'),
            _Insight(
              'Rent Share',
              '${data.totalRevenue == 0 ? 0 : (data.rentRevenue / data.totalRevenue * 100).toStringAsFixed(0)}%',
            ),
          ]),
        ),
      ],
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[Text(label, style: TextStyle(color: Colors.white.withValues(alpha: .65))), const SizedBox(height: 2), Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))]));
}

class _Insight extends StatelessWidget {
  const _Insight(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => AppDashboardCard(padding: const EdgeInsets.all(AppSpacing.sm), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[Text(label, style: Theme.of(context).textTheme.bodySmall), Text(value, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700))]));
}

class _LoadingContent extends StatelessWidget {
  const _LoadingContent();
  @override
  Widget build(BuildContext context) => const SizedBox(height: 360, child: Center(child: CircularProgressIndicator()));
}

class _EmptyContent extends StatelessWidget {
  const _EmptyContent();
  @override
  Widget build(BuildContext context) => const SizedBox(height: 360, child: Center(child: Text('No financial data for this period.')));
}

class _ErrorContent extends StatelessWidget {
  const _ErrorContent({required this.error});
  final String error;
  @override
  Widget build(BuildContext context) => AppDashboardCard(child: Column(children: <Widget>[const Icon(Icons.error_outline_rounded, size: 48), const SizedBox(height: AppSpacing.md), Text(error, textAlign: TextAlign.center), const SizedBox(height: AppSpacing.md), FilledButton(onPressed: () => context.read<ProfitLossCubit>().refresh(), child: const Text('Retry'))]));
}
