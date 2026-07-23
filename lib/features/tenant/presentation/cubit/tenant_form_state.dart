import 'package:equatable/equatable.dart';
import '../../domain/entities/tenant_status.dart';
import '../../../room/domain/entities/bed_entity.dart';

class TenantFormState extends Equatable {
  final DateTime? checkInDate;
  final DateTime? checkOutDate;
  final TenantStatus status;
  final BedEntity? selectedBed;
  final String? selectedIdType;
  final String? idDocumentPath;
  final bool isDocumentImage;
  final bool showValidationErrors;

  const TenantFormState({
    this.checkInDate,
    this.checkOutDate,
    this.status = TenantStatus.active,
    this.selectedBed,
    this.selectedIdType,
    this.idDocumentPath,
    this.isDocumentImage = false,
    this.showValidationErrors = false,
  });

  TenantFormState copyWith({
    DateTime? checkInDate,
    DateTime? checkOutDate,
    bool clearCheckOutDate = false,
    TenantStatus? status,
    BedEntity? selectedBed,
    String? selectedIdType,
    String? idDocumentPath,
    bool? isDocumentImage,
    bool? showValidationErrors,
  }) {
    return TenantFormState(
      checkInDate: checkInDate ?? this.checkInDate,
      checkOutDate:
          clearCheckOutDate ? null : (checkOutDate ?? this.checkOutDate),
      status: status ?? this.status,
      selectedBed: selectedBed ?? this.selectedBed,
      selectedIdType: selectedIdType ?? this.selectedIdType,
      idDocumentPath: idDocumentPath ?? this.idDocumentPath,
      isDocumentImage: isDocumentImage ?? this.isDocumentImage,
      showValidationErrors: showValidationErrors ?? this.showValidationErrors,
    );
  }

  @override
  List<Object?> get props => [
        checkInDate,
        checkOutDate,
        status,
        selectedBed,
        selectedIdType,
        idDocumentPath,
        isDocumentImage,
        showValidationErrors,
      ];
}
