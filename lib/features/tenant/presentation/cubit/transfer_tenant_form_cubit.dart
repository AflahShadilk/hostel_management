import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../room/domain/entities/bed_entity.dart';

class TransferTenantFormCubit extends Cubit<BedEntity?> {
  TransferTenantFormCubit() : super(null);

  void selectBed(BedEntity? bed) {
    emit(bed);
  }
}
