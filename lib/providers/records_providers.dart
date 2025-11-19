import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/intake_record.dart';
import '../models/daily_medication_status.dart';
import 'patient_providers.dart';

// 日期範圍的服藥紀錄 provider
final intakeRecordsProvider = Provider.family<List<IntakeRecord>, DateRange>((ref, range) {
  final repository = ref.watch(demoRepositoryProvider);
  final selectedPatient = ref.watch(selectedPatientProvider);
  
  if (selectedPatient == null) return [];
  
  return repository.getIntakeRecordsRange(
    selectedPatient.id, 
    range.startDate, 
    range.endDate
  );
});

// 按日期分組的服藥紀錄 provider
final groupedIntakeRecordsProvider = Provider.family<Map<String, List<IntakeRecord>>, DateRange>((ref, range) {
  final records = ref.watch(intakeRecordsProvider(range));
  
  final grouped = <String, List<IntakeRecord>>{};
  
  for (final record in records) {
    final dateKey = '${record.timestamp.year}-${record.timestamp.month}-${record.timestamp.day}';
    if (!grouped.containsKey(dateKey)) {
      grouped[dateKey] = [];
    }
    grouped[dateKey]!.add(record);
  }
  
  // 按日期排序
  final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
  final sortedGrouped = <String, List<IntakeRecord>>{};
  
  for (final key in sortedKeys) {
    sortedGrouped[key] = grouped[key]!;
  }
  
  return sortedGrouped;
});

// 特定日期的服藥紀錄 provider
final dailyIntakeRecordsProvider = Provider.family<List<IntakeRecord>, DateTime>((ref, date) {
  final repository = ref.watch(demoRepositoryProvider);
  final selectedPatient = ref.watch(selectedPatientProvider);
  
  if (selectedPatient == null) return [];
  
  return repository.getIntakeRecords(selectedPatient.id, date);
});

// 按狀態篩選的服藥紀錄 provider
final filteredIntakeRecordsProvider = Provider.family<List<IntakeRecord>, IntakeStatus?>((ref, status) {
  final repository = ref.watch(demoRepositoryProvider);
  final selectedPatient = ref.watch(selectedPatientProvider);
  
  if (selectedPatient == null) return [];
  
  final endDate = DateTime.now();
  final startDate = endDate.subtract(Duration(days: 30));
  final records = repository.getIntakeRecordsRange(selectedPatient.id, startDate, endDate);
  
  if (status == null) return records;
  
  return records.where((record) => record.status == status).toList();
});

// 服藥統計 provider
final intakeStatisticsProvider = Provider<Map<String, int>>((ref) {
  final repository = ref.watch(demoRepositoryProvider);
  final selectedPatient = ref.watch(selectedPatientProvider);
  
  if (selectedPatient == null) return {'onTime': 0, 'late': 0, 'missed': 0, 'total': 0};
  
  final endDate = DateTime.now();
  final startDate = endDate.subtract(Duration(days: 30));
  final records = repository.getIntakeRecordsRange(selectedPatient.id, startDate, endDate);
  
  int onTime = 0;
  int late = 0;
  int missed = 0;
  
  for (final record in records) {
    switch (record.status) {
      case IntakeStatus.onTime:
        onTime++;
        break;
      case IntakeStatus.late:
        late++;
        break;
      case IntakeStatus.missed:
        missed++;
        break;
    }
  }
  
  return {
    'onTime': onTime,
    'late': late,
    'missed': missed,
    'total': records.length,
  };
});

// 每日整體服藥狀態 provider
final dailyMedicationStatusProvider = Provider.family<List<DailyMedicationStatus>, int>((ref, days) {
  final repository = ref.watch(demoRepositoryProvider);
  final selectedPatient = ref.watch(selectedPatientProvider);
  
  if (selectedPatient == null) return [];
  
  return repository.getDailyMedicationStatus(selectedPatient.id, days);
});

// 日期範圍類別
class DateRange {
  final DateTime startDate;
  final DateTime endDate;
  
  const DateRange({
    required this.startDate,
    required this.endDate,
  });
  
  // 最近7天
  static DateRange get last7Days {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: 7));
    return DateRange(startDate: startDate, endDate: endDate);
  }
  
  // 最近30天
  static DateRange get last30Days {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: 30));
    return DateRange(startDate: startDate, endDate: endDate);
  }
  
  // 最近90天
  static DateRange get last90Days {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: 90));
    return DateRange(startDate: startDate, endDate: endDate);
  }
}
