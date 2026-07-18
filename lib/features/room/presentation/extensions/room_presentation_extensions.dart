import '../../domain/entities/room_type.dart';
import '../../domain/entities/room_status.dart';

extension RoomTypeLabel on RoomType {
  String get label {
    switch (this) {
      case RoomType.single:
        return 'Single';
      case RoomType.double:
        return 'Double';
      case RoomType.triple:
        return 'Triple';
      case RoomType.dormitory:
        return 'Dormitory';
      case RoomType.other:
        return 'Other';
    }
  }
}

extension RoomStatusLabel on RoomStatus {
  String get label {
    switch (this) {
      case RoomStatus.vacant:
        return 'Vacant';
      case RoomStatus.partiallyOccupied:
        return 'Partially Occupied';
      case RoomStatus.occupied:
        return 'Occupied';
      case RoomStatus.inactive:
        return 'Inactive';
    }
  }
}

/// Lightweight formatting helper for monthly rent without intl dependency.
String formatRent(double amount) {
  final whole = amount.truncate();
  if (amount == whole) {
    // No fractional part – format as integer with comma separators.
    return '₹${_formatWithCommas(whole)} / month';
  }
  return '₹${amount.toStringAsFixed(2)} / month';
}

String _formatWithCommas(int value) {
  final s = value.toString();
  final buffer = StringBuffer();
  final len = s.length;
  for (int i = 0; i < len; i++) {
    if (i == len - 3 && i != 0) buffer.write(',');
    if (i < len - 3 && (len - i - 3) % 2 == 0 && i != 0) buffer.write(',');
    buffer.write(s[i]);
  }
  return buffer.toString();
}
