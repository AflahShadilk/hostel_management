import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/app_loading_indicator.dart';
import '../cubit/tenant_history_detail_cubit.dart';

class TenantHistoryDetailPage extends StatefulWidget {
  final String stayIdStr;

  const TenantHistoryDetailPage({super.key, required this.stayIdStr});

  @override
  State<TenantHistoryDetailPage> createState() => _TenantHistoryDetailPageState();
}

class _TenantHistoryDetailPageState extends State<TenantHistoryDetailPage> {
  @override
  void initState() {
    super.initState();
    final stayId = int.tryParse(widget.stayIdStr);
    if (stayId != null) {
      context.read<TenantHistoryDetailCubit>().loadDetail(stayId);
    }
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stay Details'),
      ),
      body: BlocBuilder<TenantHistoryDetailCubit, TenantHistoryDetailState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const AppLoadingIndicator();
          }

          if (state.error != null) {
            return Center(child: Text(state.error!));
          }

          final detail = state.detail;
          if (detail == null) {
            return const Center(child: Text('Detail not found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTenantSection(detail),
                const SizedBox(height: 16),
                _buildStaySection(detail),
                const SizedBox(height: 16),
                _buildBillingTimeline(detail),
                const SizedBox(height: 16),
                _buildPaymentsSection(detail),
                const SizedBox(height: 16),
                _buildDepositSection(detail),
                const SizedBox(height: 16),
                _buildSettlementSection(detail),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: child,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTenantSection(dynamic detail) {
    final t = detail.tenant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Tenant Information', Icons.person),
        _buildCard(
          child: Column(
            children: [
              _buildInfoRow('Name', t.fullName, isBold: true),
              _buildInfoRow('Phone', t.phoneNumber),
              _buildInfoRow('Email', t.email ?? 'N/A'),
              _buildInfoRow('Emergency Contact', '${t.emergencyContactName ?? 'N/A'} (${t.emergencyContactPhone ?? ''})'),
              _buildInfoRow('Address', t.address ?? 'N/A'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStaySection(dynamic detail) {
    final s = detail.stay;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Stay Information', Icons.hotel),
        _buildCard(
          child: Column(
            children: [
              _buildInfoRow('Room', '${s.roomId}'),
              _buildInfoRow('Bed', '${s.bedId}'),
              _buildInfoRow('Check-in', _formatDate(s.checkInDate)),
              _buildInfoRow('Check-out', s.checkOutDate != null ? _formatDate(s.checkOutDate!) : 'N/A'),
              _buildInfoRow('Total Stay Days', '${detail.totalStayDays}'),
              _buildInfoRow('Monthly Rent', '₹${s.monthlyRentSnapshot.toInt()}'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBillingTimeline(dynamic detail) {
    final records = detail.rentRecords;
    if (records.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Billing Timeline', Icons.timeline),
          _buildCard(child: const Text('No billing records found.')),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Billing Timeline', Icons.timeline),
        _buildCard(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: records.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final r = records[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_formatDate(r.startDate)} → ${_formatDate(r.endDate)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          r.status.toUpperCase(),
                          style: TextStyle(
                            color: r.status == 'paid' ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(r.amountDue == detail.stay.monthlyRentSnapshot ? 'Full Month' : 'Prorated'),
                        Text('₹${r.amountDue.toInt()}'),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentsSection(dynamic detail) {
    final payments = detail.payments;
    if (payments.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Payments', Icons.payments),
          _buildCard(child: const Text('No payments recorded.')),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Payments', Icons.payments),
        _buildCard(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: payments.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final p = payments[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_formatDate(p.paymentDate), style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('₹${p.amount.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Method: ${p.paymentMethod}'),
                        Text('Ref: ${p.receiptNumber}', style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDepositSection(dynamic detail) {
    final d = detail.deposit;
    if (d == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Deposit', Icons.security),
          _buildCard(child: const Text('No deposit recorded.')),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Deposit', Icons.security),
        _buildCard(
          child: Column(
            children: [
              _buildInfoRow('Collected', '₹${d.amount.toInt()}'),
              _buildInfoRow('Returned', '₹${d.refundedAmount.toInt()}'),
              _buildInfoRow('Remaining', '₹${(d.amount - d.refundedAmount).toInt()}'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettlementSection(dynamic detail) {
    final cs = detail.checkoutSettlement;
    if (cs == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Checkout Settlement', Icons.receipt_long),
          _buildCard(child: const Text('No settlement recorded.')),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Checkout Settlement', Icons.receipt_long),
        _buildCard(
          child: Column(
            children: [
              _buildInfoRow('Pending Rent', '₹${(cs.outstandingAmount - (cs.currentMonthCharge ?? 0)).toInt()}'),
              _buildInfoRow('Current Month', '₹${(cs.currentMonthCharge ?? 0).toInt()}'),
              _buildInfoRow('Damage', '₹${cs.damageCharges.toInt()}'),
              _buildInfoRow('Deposit Used', '₹${cs.depositAdjustment.toInt()}'),
              _buildInfoRow('Deposit Returned', '₹${cs.refundAmount.toInt()}'),
              const Divider(),
              _buildInfoRow('Final Amount', '₹${cs.finalAmount.toInt()}', isBold: true),
              _buildInfoRow('Status', cs.status.toUpperCase(), isBold: true),
            ],
          ),
        ),
      ],
    );
  }
}
