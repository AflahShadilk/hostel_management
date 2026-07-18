import '../../domain/entities/bed_status.dart';

extension BedStatusLabel on BedStatus {
  String get label {
    switch (this) {
      case BedStatus.vacant:
        return 'Vacant';
      case BedStatus.occupied:
        return 'Occupied';
      case BedStatus.inactive:
        return 'Inactive';
    }
  }
}
