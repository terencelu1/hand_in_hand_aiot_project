import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/vital_sample.dart';
import '../models/intake_record.dart';
import '../models/env_reading.dart';
import 'patient_providers.dart';

// 今日生命跡象 provider（使用 FutureProvider 支援 async）
final todayVitalsProvider = FutureProvider<VitalSample?>((ref) async {
  final repository = ref.watch(demoRepositoryProvider);
  final selectedPatient = ref.watch(selectedPatientProvider);
  
  if (selectedPatient == null) return null;
  
  final today = DateTime.now();
  return await repository.getVitalSample(selectedPatient.id, today);
});

// 近5天生命跡象 provider（確保每天只有一個數據點）
final fiveDayVitalsProvider = FutureProvider<List<VitalSample>>((ref) async {
  final repository = ref.watch(demoRepositoryProvider);
  final selectedPatient = ref.watch(selectedPatientProvider);
  
  if (selectedPatient == null) return [];
  
  // 使用 async 版本，但只取每天第一個
  final samples = await repository.getVitalSamples(selectedPatient.id, 5);
  // 按日期去重，只保留每天的第一個
  final dateMap = <String, VitalSample>{};
  for (final sample in samples) {
    final dateKey = '${sample.timestamp.year}-${sample.timestamp.month}-${sample.timestamp.day}';
    if (!dateMap.containsKey(dateKey)) {
      dateMap[dateKey] = sample;
    }
  }
  return dateMap.values.toList()..sort((a, b) => a.timestamp.compareTo(b.timestamp));
});

// 近7天生命跡象 provider（確保每天只有一個數據點）
final weeklyVitalsProvider = FutureProvider<List<VitalSample>>((ref) async {
  final repository = ref.watch(demoRepositoryProvider);
  final selectedPatient = ref.watch(selectedPatientProvider);
  
  if (selectedPatient == null) return [];
  
  final samples = await repository.getVitalSamples(selectedPatient.id, 7);
  // 按日期去重，只保留每天的第一個
  final dateMap = <String, VitalSample>{};
  for (final sample in samples) {
    final dateKey = '${sample.timestamp.year}-${sample.timestamp.month}-${sample.timestamp.day}';
    if (!dateMap.containsKey(dateKey)) {
      dateMap[dateKey] = sample;
    }
  }
  return dateMap.values.toList()..sort((a, b) => a.timestamp.compareTo(b.timestamp));
});

// 近30天生命跡象 provider
final monthlyVitalsProvider = FutureProvider<List<VitalSample>>((ref) async {
  final repository = ref.watch(demoRepositoryProvider);
  final selectedPatient = ref.watch(selectedPatientProvider);
  
  if (selectedPatient == null) return [];
  
  return await repository.getVitalSamples(selectedPatient.id, 30);
});

// 今日用藥摘要 provider
final todaySummaryProvider = Provider<Map<String, int>>((ref) {
  final repository = ref.watch(demoRepositoryProvider);
  final selectedPatient = ref.watch(selectedPatientProvider);
  
  if (selectedPatient == null) return {'onTime': 0, 'late': 0, 'missed': 0};
  
  return repository.getTodayMedicationSummary(selectedPatient.id);
});

// 今日服藥紀錄 provider
final todayRecordsProvider = Provider<List<IntakeRecord>>((ref) {
  final repository = ref.watch(demoRepositoryProvider);
  final selectedPatient = ref.watch(selectedPatientProvider);
  
  if (selectedPatient == null) return [];
  
  final today = DateTime.now();
  return repository.getIntakeRecords(selectedPatient.id, today);
});

// 近7天服藥紀錄 provider
final weeklyRecordsProvider = Provider<List<IntakeRecord>>((ref) {
  final repository = ref.watch(demoRepositoryProvider);
  final selectedPatient = ref.watch(selectedPatientProvider);
  
  if (selectedPatient == null) return [];
  
  final endDate = DateTime.now();
  final startDate = endDate.subtract(Duration(days: 7));
  return repository.getIntakeRecordsRange(selectedPatient.id, startDate, endDate);
});

// 近30天服藥紀錄 provider
final monthlyRecordsProvider = Provider<List<IntakeRecord>>((ref) {
  final repository = ref.watch(demoRepositoryProvider);
  final selectedPatient = ref.watch(selectedPatientProvider);
  
  if (selectedPatient == null) return [];
  
  final endDate = DateTime.now();
  final startDate = endDate.subtract(Duration(days: 30));
  return repository.getIntakeRecordsRange(selectedPatient.id, startDate, endDate);
});

// 今日環境讀數 provider
final todayEnvReadingsProvider = FutureProvider<List<EnvReading>>((ref) async {
  final repository = ref.watch(demoRepositoryProvider);
  final selectedPatient = ref.watch(selectedPatientProvider);
  
  if (selectedPatient == null) return [];
  
  final today = DateTime.now();
  return await repository.getEnvReadings(selectedPatient.id, today);
});

// 近5天環境讀數 provider（每天只取第一個數據點）
final fiveDayEnvReadingsProvider = FutureProvider<List<EnvReading>>((ref) async {
  final repository = ref.watch(demoRepositoryProvider);
  final selectedPatient = ref.watch(selectedPatientProvider);
  
  if (selectedPatient == null) return [];
  
  final endDate = DateTime.now();
  final startDate = endDate.subtract(Duration(days: 5));
  return repository.getEnvReadingsRangeFirstOnly(selectedPatient.id, startDate, endDate);
});

// 近7天環境讀數 provider
final weeklyEnvReadingsProvider = FutureProvider<List<EnvReading>>((ref) async {
  final repository = ref.watch(demoRepositoryProvider);
  final selectedPatient = ref.watch(selectedPatientProvider);
  
  if (selectedPatient == null) return [];
  
  final endDate = DateTime.now();
  final startDate = endDate.subtract(Duration(days: 7));
  return repository.getEnvReadingsRange(selectedPatient.id, startDate, endDate);
});

// 服藥依從性統計 provider
final medicationComplianceProvider = Provider.family<Map<String, int>, int>((ref, days) {
  final repository = ref.watch(demoRepositoryProvider);
  final selectedPatient = ref.watch(selectedPatientProvider);
  
  if (selectedPatient == null) return {'onTime': 0, 'total': 0, 'late': 0, 'missed': 0};
  
  return repository.getMedicationCompliance(selectedPatient.id, days);
});

// 刷新今日生命跡象 provider
final refreshVitalsProvider = StateNotifierProvider<RefreshVitalsNotifier, bool>((ref) {
  return RefreshVitalsNotifier(ref);
});

class RefreshVitalsNotifier extends StateNotifier<bool> {
  final Ref _ref;
  
  RefreshVitalsNotifier(this._ref) : super(false);

  Future<void> refreshTodayVitals() async {
    state = true;
    
    final repository = _ref.read(demoRepositoryProvider);
    final selectedPatient = _ref.read(selectedPatientProvider);
    
    if (selectedPatient != null) {
      await repository.refreshTodayVitals(selectedPatient.id);
      // 觸發重新計算
      _ref.invalidate(todayVitalsProvider);
    }
    
    // 模擬載入時間
    await Future.delayed(Duration(milliseconds: 500));
    state = false;
  }
}
