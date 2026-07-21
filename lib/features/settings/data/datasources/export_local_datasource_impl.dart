import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../features/auth/domain/services/auth_session_service.dart';
import '../../../../features/expense/domain/entities/expense_entity.dart';
import '../../../../features/expense/domain/repositories/expense_repository.dart';
import '../../../../features/hostel/domain/repositories/hostel_repository.dart';
import '../../../../features/rent/domain/entities/rent_record_entity.dart';
import '../../../../features/rent/domain/repositories/rent_repository.dart';
import '../../../../features/room/domain/entities/room_entity.dart';
import '../../../../features/room/domain/repositories/room_repository.dart';
import '../../../../features/tenant/domain/entities/tenant_entity.dart';
import '../../../../features/tenant/domain/repositories/tenant_repository.dart';
import '../../domain/repositories/export_repository.dart';
import 'export_local_datasource.dart';

class ExportLocalDataSourceImpl implements ExportLocalDataSource {
  const ExportLocalDataSourceImpl(
    this._tenantRepository,
    this._roomRepository,
    this._rentRepository,
    this._expenseRepository,
    this._hostelRepository,
    this._sessionService,
  );

  final TenantRepository _tenantRepository;
  final RoomRepository _roomRepository;
  final RentRepository _rentRepository;
  final ExpenseRepository _expenseRepository;
  final HostelRepository _hostelRepository;
  final AuthSessionService _sessionService;

  @override
  Future<ExportResult> export(ExportDataType type) async {
    try {
      final content = await _contentFor(type);
      if (content.rows.isEmpty) {
        return const ExportFailure('There are no records available to export.');
      }

      final destination = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Choose export destination',
      );
      if (destination == null) return const ExportCancelled();

      final filePath = path.join(destination, _fileName(type));
      if (content.isPdf) {
        await File(filePath).writeAsBytes(await _pdf(content).save());
      } else {
        await File(filePath).writeAsBytes(utf8.encode(_csv(content)));
      }
      return ExportSuccess('Export saved at $filePath.');
    } on FileSystemException catch (error) {
      return ExportFailure('Unable to write export: ${error.message}');
    } catch (error) {
      return ExportFailure('Unable to export data: $error');
    }
  }

  Future<_ExportContent> _contentFor(ExportDataType type) async {
    switch (type) {
      case ExportDataType.tenantCsv:
      case ExportDataType.tenantPdf:
        return _tenantContent(await _tenantRepository.getAllTenants(), type);
      case ExportDataType.roomCsv:
        return _roomContent(await _rooms(), type);
      case ExportDataType.rentCsv:
      case ExportDataType.rentPdf:
        return _rentContent(await _rentRepository.getAllRentRecords(), type);
      case ExportDataType.expenseCsv:
      case ExportDataType.expensePdf:
        return _expenseContent(await _expenseRepository.getAllExpenses(), type);
    }
  }

  Future<List<RoomEntity>> _rooms() async {
    final userId = await _sessionService.getUserId();
    if (userId == null) return const [];
    final hostel = await _hostelRepository.getHostelByOwnerUserId(userId);
    if (hostel == null || hostel.id == null) return const [];
    return _roomRepository.getRoomsByHostelId(hostel.id!);
  }

  _ExportContent _tenantContent(List<TenantEntity> tenants, ExportDataType type) {
    return _ExportContent(
      title: 'Tenant Summary',
      isPdf: type == ExportDataType.tenantPdf,
      headers: const ['ID', 'Name', 'Phone', 'Email', 'Bed', 'Status'],
      rows: tenants
          .map((tenant) => [
                '${tenant.id ?? ''}',
                tenant.fullName,
                tenant.phoneNumber,
                tenant.email ?? '',
                '${tenant.bedId ?? ''}',
                tenant.status.name,
              ])
          .toList(),
    );
  }

  _ExportContent _roomContent(List<RoomEntity> rooms, ExportDataType type) {
    return _ExportContent(
      title: 'Room List',
      isPdf: false,
      headers: const ['ID', 'Room', 'Floor', 'Type', 'Beds', 'Monthly Rent', 'Status'],
      rows: rooms
          .map((room) => [
                '${room.id ?? ''}',
                room.roomNumber,
                room.floor,
                room.roomType.name,
                '${room.numberOfBeds}',
                room.monthlyRent.toStringAsFixed(2),
                room.status.name,
              ])
          .toList(),
    );
  }

  _ExportContent _rentContent(List<RentRecordEntity> records, ExportDataType type) {
    final totalDue = records.fold<double>(0, (total, record) => total + record.amountDue);
    final totalPaid = records.fold<double>(0, (total, record) => total + record.amountPaid);
    return _ExportContent(
      title: 'Rent Report',
      isPdf: type == ExportDataType.rentPdf,
      headers: const ['ID', 'Stay', 'Billing', 'Due Date', 'Amount Due', 'Amount Paid', 'Balance', 'Status'],
      rows: records
          .map((record) => [
                '${record.id ?? ''}',
                '${record.stayId}',
                record.formattedPeriod,
                _date(record.dueDate),
                record.amountDue.toStringAsFixed(2),
                record.amountPaid.toStringAsFixed(2),
                (record.amountDue - record.amountPaid).toStringAsFixed(2),
                record.status,
              ])
          .toList(),
      total: 'Total due: ${totalDue.toStringAsFixed(2)}   '
          'Total paid: ${totalPaid.toStringAsFixed(2)}   '
          'Balance: ${(totalDue - totalPaid).toStringAsFixed(2)}',
    );
  }

  _ExportContent _expenseContent(List<ExpenseEntity> expenses, ExportDataType type) {
    final total = expenses.fold<double>(0, (value, expense) => value + expense.amount);
    return _ExportContent(
      title: 'Expense Report',
      isPdf: type == ExportDataType.expensePdf,
      headers: const ['ID', 'Category', 'Title', 'Amount', 'Date', 'Payment Method', 'Reference'],
      rows: expenses
          .map((expense) => [
                '${expense.id ?? ''}',
                '${expense.categoryId}',
                expense.title,
                expense.amount.toStringAsFixed(2),
                _date(expense.expenseDate),
                expense.paymentMethod,
                expense.referenceNumber ?? '',
              ])
          .toList(),
      total: 'Total expenses: ${total.toStringAsFixed(2)}',
    );
  }

  String _fileName(ExportDataType type) {
    final today = DateTime.now();
    final date = '${today.year.toString().padLeft(4, '0')}'
        '${today.month.toString().padLeft(2, '0')}'
        '${today.day.toString().padLeft(2, '0')}';
    return switch (type) {
      ExportDataType.tenantCsv => 'tenant_list_$date.csv',
      ExportDataType.roomCsv => 'room_list_$date.csv',
      ExportDataType.rentCsv => 'rent_records_$date.csv',
      ExportDataType.expenseCsv => 'expense_records_$date.csv',
      ExportDataType.tenantPdf => 'tenant_summary_$date.pdf',
      ExportDataType.rentPdf => 'rent_report_$date.pdf',
      ExportDataType.expensePdf => 'expense_report_$date.pdf',
    };
  }

  String _csv(_ExportContent content) {
    final rows = [content.headers, ...content.rows];
    return '${rows.map((row) => row.map(_escapeCsv).join(',')).join('\r\n')}\r\n';
  }

  String _escapeCsv(String value) => '"${value.replaceAll('"', '""')}"';

  pw.Document _pdf(_ExportContent content) {
    final document = pw.Document();
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (_) => [
          pw.Text(content.title, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.Text('Generated: ${_date(DateTime.now())}'),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: content.headers,
            data: content.rows,
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellAlignment: pw.Alignment.centerLeft,
          ),
          if (content.total != null) ...[
            pw.SizedBox(height: 16),
            pw.Text(content.total!, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          ],
        ],
      ),
    );
    return document;
  }

  String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}

class _ExportContent {
  const _ExportContent({
    required this.title,
    required this.isPdf,
    required this.headers,
    required this.rows,
    this.total,
  });

  final String title;
  final bool isPdf;
  final List<String> headers;
  final List<List<String>> rows;
  final String? total;
}
