import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/profit_loss_entity.dart';
import '../cubit/profit_loss_cubit.dart';
import '../cubit/profit_loss_state.dart';
import '../cubit/reports_date_filter.dart';

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
      if (!mounted) return;
      context.read<ProfitLossCubit>().loadWithFilter(ReportsDateFilter.thisMonth);
    });
  }

  Future<void> _pickCustomRange(BuildContext context) async {
    // Capture the cubit reference before any async gap.
    final cubit = context.read<ProfitLossCubit>();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2099),
      builder: (ctx, child) => Theme(data: Theme.of(ctx), child: child!),
    );
    if (range != null && mounted) {
      final end = DateTime(range.end.year, range.end.month, range.end.day, 23, 59, 59);
      await cubit.loadWithCustomRange(range.start, end);
    }
  }

  String _fmt(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]}';
  }

  String _formatCurrency(double amount) {
    // Format as Indian number system: ₹1,23,456
    final abs = amount.abs().round();
    final str = abs.toString();
    if (str.length <= 3) return '₹$str';
    final last3 = str.substring(str.length - 3);
    final rest = str.substring(0, str.length - 3);
    final withCommas = rest.replaceAllMapped(RegExp(r'(\d{1,2})(?=\d)'), (m) => '${m[0]},');
    return '₹$withCommas,$last3';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      body: BlocBuilder<ProfitLossCubit, ProfitLossState>(
        builder: (context, state) {
          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(context, cs, tt, state),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(
                    _buildBody(context, cs, tt, state),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  SliverAppBar _buildSliverAppBar(
    BuildContext context,
    ColorScheme cs,
    TextTheme tt,
    ProfitLossState state,
  ) {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      stretch: true,
      backgroundColor: cs.primaryContainer,
      foregroundColor: cs.onPrimaryContainer,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                cs.primary,
                cs.primaryContainer,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Icon(Icons.bar_chart_rounded, color: cs.onPrimary, size: 28),
                      const SizedBox(width: 10),
                      Text(
                        'Profit & Loss',
                        style: tt.headlineMedium?.copyWith(
                          color: cs.onPrimary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Financial overview of the hostel',
                    style: tt.bodyMedium?.copyWith(
                      color: cs.onPrimary.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          color: cs.primaryContainer.withValues(alpha: 0.6),
          child: _buildFilterChips(context, cs, state),
        ),
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context, ColorScheme cs, ProfitLossState state) {
    final filters = [
      ReportsDateFilter.today,
      ReportsDateFilter.thisWeek,
      ReportsDateFilter.thisMonth,
      ReportsDateFilter.thisYear,
      ReportsDateFilter.custom,
    ];

    return SizedBox(
      height: 60,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final f = filters[i];
          final isSelected = state.activeFilter == f;
          return FilterChip(
            label: Text(
              f == ReportsDateFilter.custom && state.activeFilter == ReportsDateFilter.custom && state.customFrom != null
                  ? '${_fmt(state.customFrom!)} – ${_fmt(state.customTo!)}'
                  : f.label,
            ),
            selected: isSelected,
            onSelected: (_) {
              if (f == ReportsDateFilter.custom) {
                _pickCustomRange(context);
              } else {
                context.read<ProfitLossCubit>().loadWithFilter(f);
              }
            },
            selectedColor: cs.primary,
            labelStyle: TextStyle(
              color: isSelected ? cs.onPrimary : cs.onSurface,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
            checkmarkColor: cs.onPrimary,
            side: BorderSide.none,
          );
        },
      ),
    );
  }

  List<Widget> _buildBody(
    BuildContext context,
    ColorScheme cs,
    TextTheme tt,
    ProfitLossState state,
  ) {
    if (state.isLoading && state.data == null) {
      return [_buildSkeleton(cs)];
    }

    if (state.error != null && state.data == null) {
      return [_buildError(context, cs, tt, state.error!)];
    }

    if (state.data == null) {
      return [_buildEmpty(cs, tt)];
    }

    final d = state.data!;

    return [
      const SizedBox(height: 20),
      _buildNetProfitHero(cs, tt, d),
      const SizedBox(height: 16),
      _buildKpiGrid(cs, tt, d),
      const SizedBox(height: 16),
      _buildRevenueBreakdown(cs, tt, d),
      const SizedBox(height: 16),
      _buildInsightsCard(cs, tt, d),
    ];
  }

  // ── NET PROFIT HERO ────────────────────────────────────────────────────────

  Widget _buildNetProfitHero(ColorScheme cs, TextTheme tt, ProfitLossEntity d) {
    final isProfit = d.isProfit;
    final bgColor = isProfit
        ? const Color(0xFF1B5E20)
        : const Color(0xFF7F0000);
    final accentColor = isProfit
        ? const Color(0xFF69F0AE)
        : const Color(0xFFFF8A80);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [bgColor, bgColor.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: bgColor.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: accentColor.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isProfit ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                      color: accentColor,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isProfit ? 'Profit' : 'Loss',
                      style: TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Icon(Icons.account_balance_wallet_rounded, color: Colors.white.withValues(alpha: 0.5), size: 32),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Net Profit',
            style: tt.titleMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.7),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            (d.isProfit ? '' : '−') + _formatCurrency(d.netProfit),
            style: tt.displaySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildHeroStat('Revenue', _formatCurrency(d.totalRevenue), Colors.white),
              const SizedBox(width: 24),
              _buildHeroStat('Expenses', _formatCurrency(d.totalExpenses), Colors.white),
              const SizedBox(width: 24),
              _buildHeroStat(
                'Margin',
                '${d.profitMargin.toStringAsFixed(1)}%',
                accentColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStat(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  // ── KPI GRID ───────────────────────────────────────────────────────────────

  Widget _buildKpiGrid(ColorScheme cs, TextTheme tt, ProfitLossEntity d) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.35,
      children: [
        _KpiCard(
          icon: Icons.payments_rounded,
          iconColor: const Color(0xFF1976D2),
          label: 'Total Revenue',
          value: _formatCurrency(d.totalRevenue),
          subtitle: 'Collected payments',
          containerColor: const Color(0xFFE3F2FD),
        ),
        _KpiCard(
          icon: Icons.receipt_long_rounded,
          iconColor: const Color(0xFFC62828),
          label: 'Total Expenses',
          value: _formatCurrency(d.totalExpenses),
          subtitle: 'Operational costs',
          containerColor: const Color(0xFFFFEBEE),
        ),
        _KpiCard(
          icon: d.isProfit ? Icons.trending_up_rounded : Icons.trending_down_rounded,
          iconColor: d.isProfit ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
          label: 'Net Profit',
          value: (d.isProfit ? '' : '−') + _formatCurrency(d.netProfit),
          subtitle: d.isProfit ? 'Profitable period' : 'Loss period',
          containerColor: d.isProfit ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
        ),
        _KpiCard(
          icon: Icons.donut_large_rounded,
          iconColor: const Color(0xFF6A1B9A),
          label: 'Profit Margin',
          value: '${d.profitMargin.toStringAsFixed(1)}%',
          subtitle: 'Revenue efficiency',
          containerColor: const Color(0xFFF3E5F5),
        ),
      ],
    );
  }

  // ── REVENUE BREAKDOWN ─────────────────────────────────────────────────────

  Widget _buildRevenueBreakdown(ColorScheme cs, TextTheme tt, ProfitLossEntity d) {
    final total = d.totalRevenue;

    return _SectionCard(
      title: 'Revenue Breakdown',
      icon: Icons.pie_chart_outline_rounded,
      child: Column(
        children: [
          _RevenueBar(
            label: 'Rent',
            icon: Icons.home_rounded,
            amount: d.rentRevenue,
            total: total,
            color: const Color(0xFF1976D2),
            formattedAmount: _formatCurrency(d.rentRevenue),
          ),
          const SizedBox(height: 16),
          _RevenueBar(
            label: 'Damage Charges',
            icon: Icons.construction_rounded,
            amount: d.damageChargeRevenue,
            total: total,
            color: const Color(0xFFE65100),
            formattedAmount: _formatCurrency(d.damageChargeRevenue),
          ),
          const SizedBox(height: 16),
          _RevenueBar(
            label: 'Other Income',
            icon: Icons.add_circle_outline_rounded,
            amount: d.otherRevenue,
            total: total,
            color: const Color(0xFF388E3C),
            formattedAmount: _formatCurrency(d.otherRevenue),
          ),
        ],
      ),
    );
  }

  // ── QUICK INSIGHTS ────────────────────────────────────────────────────────

  Widget _buildInsightsCard(ColorScheme cs, TextTheme tt, ProfitLossEntity d) {
    final primarySource = d.rentRevenue >= d.damageChargeRevenue ? 'Rent' : 'Damage Charges';
    final margin = d.profitMargin;
    String marginLabel;
    Color marginColor;
    if (margin >= 40) {
      marginLabel = 'Excellent';
      marginColor = const Color(0xFF2E7D32);
    } else if (margin >= 20) {
      marginLabel = 'Good';
      marginColor = const Color(0xFF1976D2);
    } else if (margin >= 0) {
      marginLabel = 'Marginal';
      marginColor = const Color(0xFFF57F17);
    } else {
      marginLabel = 'Loss';
      marginColor = const Color(0xFFC62828);
    }

    return _SectionCard(
      title: 'Quick Insights',
      icon: Icons.lightbulb_outline_rounded,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _InsightChip(
            icon: Icons.star_rounded,
            label: 'Best Revenue Source',
            value: primarySource,
            color: const Color(0xFF1565C0),
          ),
          _InsightChip(
            icon: Icons.speed_rounded,
            label: 'Margin Health',
            value: marginLabel,
            color: marginColor,
          ),
          _InsightChip(
            icon: Icons.savings_rounded,
            label: 'Rent Revenue',
            value: '${d.totalRevenue > 0 ? (d.rentRevenue / d.totalRevenue * 100).toStringAsFixed(0) : 0}% of total',
            color: const Color(0xFF6A1B9A),
          ),
        ],
      ),
    );
  }

  // ── STATES ────────────────────────────────────────────────────────────────

  Widget _buildSkeleton(ColorScheme cs) {
    return Column(
      children: [
        const SizedBox(height: 20),
        _SkeletonBox(height: 180, radius: 24),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.35,
          children: List.generate(4, (_) => _SkeletonBox(height: 120, radius: 20)),
        ),
        const SizedBox(height: 16),
        _SkeletonBox(height: 200, radius: 20),
      ],
    );
  }

  Widget _buildEmpty(ColorScheme cs, TextTheme tt) {
    return SizedBox(
      height: 380,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.bar_chart_rounded, size: 64, color: cs.outline),
            ),
            const SizedBox(height: 24),
            Text('No Financial Data',
                style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              'No transactions found for the selected period.',
              style: tt.bodyMedium?.copyWith(color: cs.outline),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, ColorScheme cs, TextTheme tt, String error) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded, color: cs.onErrorContainer, size: 48),
          const SizedBox(height: 16),
          Text('Something went wrong',
              style: tt.titleMedium?.copyWith(color: cs.onErrorContainer, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(error, style: tt.bodySmall?.copyWith(color: cs.onErrorContainer), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => context.read<ProfitLossCubit>().refresh(),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
            style: FilledButton.styleFrom(backgroundColor: cs.onErrorContainer),
          ),
        ],
      ),
    );
  }
}

// ── REUSABLE WIDGETS ─────────────────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color containerColor;
  final String label;
  final String value;
  final String subtitle;

  const _KpiCard({
    required this.icon,
    required this.iconColor,
    required this.containerColor,
    required this.label,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: containerColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800, fontSize: 18),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(label, style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
              Text(subtitle, style: tt.bodySmall?.copyWith(color: cs.outline, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: cs.primary),
              const SizedBox(width: 8),
              Text(title,
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _RevenueBar extends StatelessWidget {
  final String label;
  final IconData icon;
  final double amount;
  final double total;
  final Color color;
  final String formattedAmount;

  const _RevenueBar({
    required this.label,
    required this.icon,
    required this.amount,
    required this.total,
    required this.color,
    required this.formattedAmount,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final fraction = (total > 0 && amount > 0) ? (amount / total).clamp(0.0, 1.0) : 0.0;
    final pct = (fraction * 100).toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Expanded(child: Text(label, style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600))),
            Text(formattedAmount, style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: color)),
            const SizedBox(width: 8),
            Text('$pct%', style: tt.bodySmall?.copyWith(color: cs.outline)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: fraction),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => LinearProgressIndicator(
              value: value,
              minHeight: 8,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
      ],
    );
  }
}

class _InsightChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InsightChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: tt.labelSmall?.copyWith(color: color.withValues(alpha: 0.7))),
              Text(value, style: tt.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SkeletonBox extends StatefulWidget {
  final double height;
  final double radius;

  const _SkeletonBox({required this.height, required this.radius});

  @override
  State<_SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<_SkeletonBox> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 0.8).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh.withValues(alpha: _anim.value),
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}
