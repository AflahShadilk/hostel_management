import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/rent_record_entity.dart';
import '../../../domain/repositories/rent_repository.dart';
import 'rent_record_state.dart';

class RentRecordCubit extends Cubit<RentRecordState> {
  final RentRepository _rentRepository;

  RentRecordCubit(this._rentRepository) : super(const RentRecordInitial());

  Future<void> createRentRecord(RentRecordEntity record) async {
    emit(const RentRecordLoading());
    try {
      await _rentRepository.createRentRecord(record);
      await _reloadAllRentRecords();
    } catch (error) {
      emit(RentRecordError(error.toString()));
    }
  }

  Future<void> loadRentRecordById(int id) async {
    emit(const RentRecordLoading());
    try {
      final record = await _rentRepository.getRentRecordById(id);
      _emitSingleRecord(record);
    } catch (error) {
      emit(RentRecordError(error.toString()));
    }
  }

  Future<void> loadRentRecordsByStayId(int stayId) async {
    emit(const RentRecordLoading());
    try {
      final records = await _rentRepository.getRentRecordsByStayId(stayId);
      _emitRecords(records);
    } catch (error) {
      emit(RentRecordError(error.toString()));
    }
  }

  Future<void> loadAllRentRecords() async {
    emit(const RentRecordLoading());
    try {
      await _reloadAllRentRecords();
    } catch (error) {
      emit(RentRecordError(error.toString()));
    }
  }

  Future<void> updateRentRecord(RentRecordEntity record) async {
    emit(const RentRecordLoading());
    try {
      await _rentRepository.updateRentRecord(record);
      await _reloadAllRentRecords();
    } catch (error) {
      emit(RentRecordError(error.toString()));
    }
  }

  Future<void> deleteRentRecord(int id) async {
    emit(const RentRecordLoading());
    try {
      await _rentRepository.deleteRentRecord(id);
      await _reloadAllRentRecords();
    } catch (error) {
      emit(RentRecordError(error.toString()));
    }
  }

  Future<void> _reloadAllRentRecords() async {
    final records = await _rentRepository.getAllRentRecords();
    _emitRecords(records);
  }

  void _emitSingleRecord(RentRecordEntity? record) {
    if (record == null) {
      emit(const RentRecordEmpty());
      return;
    }
    emit(RentRecordLoaded(<RentRecordEntity>[record]));
  }

  void _emitRecords(List<RentRecordEntity> records) {
    if (records.isEmpty) {
      emit(const RentRecordEmpty());
      return;
    }
    emit(RentRecordLoaded(records));
  }
}
