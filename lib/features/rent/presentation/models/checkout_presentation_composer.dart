import '../../../tenant/presentation/cubit/tenant_state.dart';
import '../cubit/checkout/checkout_state.dart';
import '../cubit/checkout/checkout_summary_cubit.dart';
import '../cubit/stay/stay_state.dart';
import '../../domain/constants/rent_status_constants.dart';
import 'checkout_list_item_view_model.dart';
import 'checkout_receipt_preview_view_model.dart';

/// Read-only composition of existing checkout-screen presentation states.
abstract final class CheckoutPresentationComposer {
  static List<CheckoutListItemViewModel> compose({
    required TenantState tenantState,
    required StayState stayState,
    required CheckoutSummaryState summaryState,
    required CheckoutState checkoutState,
  }) {
    if (stayState is! StayLoaded) return const <CheckoutListItemViewModel>[];

    final previews = checkoutState is CheckoutLoaded
        ? checkoutState.receiptPreviews
        : const <CheckoutReceiptPreviewViewModel>[];

    return stayState.stays
        .where((stay) => stay.status == StayStatus.active && stay.id != null)
        .map((stay) {
      final views = tenantState.viewModels
          .where((view) => view.tenant.id == stay.tenantId)
          .toList();
      final view = views.isEmpty ? null : views.first;
      final previewsForStay = previews
          .where((preview) => preview.settlement.stayId == stay.id)
          .toList();

      return CheckoutListItemViewModel(
        stayId: stay.id!,
        tenantName: view?.tenant.fullName ?? '',
        phoneNumber: view?.tenant.phoneNumber ?? '',
        roomName: view?.roomName ?? '',
        bedName: view?.bedName ?? '',
        checkInDate: stay.checkInDate,
        monthlyRent: stay.monthlyRentSnapshot,
        pendingRent: summaryState.outstandingRent,
        status: stay.status,
        receiptPreview: previewsForStay.isEmpty ? null : previewsForStay.first,
      );
    }).toList(growable: false);
  }
}
