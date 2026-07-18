import 'package:flutter_bloc/flutter_bloc.dart';
import 'bed_filter.dart';

class BedFilterCubit extends Cubit<BedFilter> {
  BedFilterCubit() : super(BedFilter.all);

  void selectFilter(BedFilter filter) {
    emit(filter);
  }
}
