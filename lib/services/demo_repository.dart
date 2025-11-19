import '../models/patient.dart';
import '../models/vital_sample.dart';
import '../models/medication.dart';
import '../models/intake_record.dart';
import '../models/env_reading.dart';
import '../models/daily_medication_status.dart';
import 'random_data_service.dart';
import 'raspberry_pi_api_service.dart';
import 'api_data_mapper.dart';

class DemoRepository {
  final RaspberryPiApiService _apiService;
  
  static final Map<String, List<Medication>> _medicationsCache = {};
  static final Map<String, Map<String, VitalSample>> _vitalsCache = {};
  static final Map<String, Map<String, List<IntakeRecord>>> _recordsCache = {};
  static final Map<String, Map<String, List<EnvReading>>> _envCache = {};
  static final Map<String, List<Map<String, dynamic>>> _notificationsCache = {};
  static List<Patient>? _cachedPatients;

  DemoRepository({RaspberryPiApiService? apiService})
      : _apiService = apiService ?? RaspberryPiApiService();

  // 取得所有病人（從 API 獲取）
  Future<List<Patient>> getAllPatients() async {
    // 如果有緩存，先返回緩存
    if (_cachedPatients != null) {
      return _cachedPatients!;
    }

    try {
      // 嘗試從 API 獲取使用者列表
      final users = await _apiService.getUsers();
      
      if (users != null && users.isNotEmpty) {
        final patients = <Patient>[];

        users.forEach((userId, userData) {
          patients.add(ApiDataMapper.patientFromApiData(userId, userData));
        });

        // 如果 API 有數據，使用 API 數據
        if (patients.isNotEmpty) {
          _cachedPatients = patients;
          return patients;
        }
      }
    } catch (e) {
      // API 失敗時使用預設數據
      print('無法從 API 獲取病人列表: $e');
    }

    // 回退到預設數據
    final defaultPatients = RandomDataService.getDefaultPatients();
    _cachedPatients = defaultPatients;
    return defaultPatients;
  }

  // 同步版本（為了向後兼容）
  List<Patient> getAllPatientsSync() {
    if (_cachedPatients != null) {
      return _cachedPatients!;
    }
    return RandomDataService.getDefaultPatients();
  }

  // 取得特定病人的用藥清單
  List<Medication> getMedications(String patientId) {
    if (!_medicationsCache.containsKey(patientId)) {
      _medicationsCache[patientId] = RandomDataService.generateMedications(patientId);
    }
    return _medicationsCache[patientId]!;
  }

  // 取得特定日期的生命跡象（從 API 獲取）
  Future<VitalSample?> getVitalSample(String patientId, DateTime date) async {
    final dateKey = '${date.year}-${date.month}-${date.day}';
    
    // 檢查緩存
    if (_vitalsCache.containsKey(patientId) && 
        _vitalsCache[patientId]!.containsKey(dateKey)) {
      return _vitalsCache[patientId]![dateKey];
    }

    // 嘗試從 API 獲取
    final userId = ApiDataMapper.patientIdToUserId(patientId);
    if (userId != null) {
      try {
        // 獲取歷史數據，找到對應日期的數據
        final history = await _apiService.getHistoryData(userId, limit: 100);
        
        for (final record in history) {
          final recordTimestamp = DateTime.parse(record['timestamp'] as String);
          final recordDateKey = '${recordTimestamp.year}-${recordTimestamp.month}-${recordTimestamp.day}';
          
          if (recordDateKey == dateKey) {
            final vital = ApiDataMapper.vitalSampleFromApiData(record);
            if (vital != null) {
              // 緩存結果
              if (!_vitalsCache.containsKey(patientId)) {
                _vitalsCache[patientId] = {};
              }
              _vitalsCache[patientId]![dateKey] = vital;
              return vital;
            }
          }
        }
      } catch (e) {
        print('無法從 API 獲取生命跡象: $e');
      }
    }

    // 如果 API 沒有數據或失敗，使用隨機數據
    if (!_vitalsCache.containsKey(patientId)) {
      _vitalsCache[patientId] = {};
    }
    _vitalsCache[patientId]![dateKey] = RandomDataService.generateVitalSample(patientId, date);
    return _vitalsCache[patientId]![dateKey];
  }

  // 同步版本（為了向後兼容）
  VitalSample? getVitalSampleSync(String patientId, DateTime date) {
    final dateKey = '${date.year}-${date.month}-${date.day}';
    
    if (!_vitalsCache.containsKey(patientId)) {
      _vitalsCache[patientId] = {};
    }
    
    if (!_vitalsCache[patientId]!.containsKey(dateKey)) {
      _vitalsCache[patientId]![dateKey] = RandomDataService.generateVitalSample(patientId, date);
    }
    
    return _vitalsCache[patientId]![dateKey];
  }

  // 取得近期的生命跡象資料（從 API 獲取）
  Future<List<VitalSample>> getVitalSamples(String patientId, int days) async {
    final userId = ApiDataMapper.patientIdToUserId(patientId);
    if (userId != null) {
      try {
        // 從 API 獲取歷史數據
        final history = await _apiService.getHistoryData(userId, limit: days * 2);
        final samples = <VitalSample>[];
        final addedDates = <String>{};
        
        // 按時間排序（最新的在前）
        history.sort((a, b) {
          final timeA = DateTime.parse(a['timestamp'] as String);
          final timeB = DateTime.parse(b['timestamp'] as String);
          return timeB.compareTo(timeA);
        });
        
        for (final record in history) {
          final recordTimestamp = DateTime.parse(record['timestamp'] as String);
          final dateKey = '${recordTimestamp.year}-${recordTimestamp.month}-${recordTimestamp.day}';
          
          // 只取最近 days 天的數據，且每個日期只取一個
          final daysDiff = DateTime.now().difference(recordTimestamp).inDays;
          if (daysDiff < days && !addedDates.contains(dateKey)) {
            final vital = ApiDataMapper.vitalSampleFromApiData(record);
            if (vital != null) {
              samples.add(vital);
              addedDates.add(dateKey);
            }
          }
        }
        
        // 按時間排序（舊的在前）
        samples.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        
        if (samples.isNotEmpty) {
          return samples;
        }
      } catch (e) {
        print('無法從 API 獲取生命跡象歷史: $e');
      }
    }

    // 回退到隨機數據
    final samples = <VitalSample>[];
    final now = DateTime.now();
    final addedDates = <String>{};
    
    for (int i = days - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey = '${date.year}-${date.month}-${date.day}';
      
      if (!addedDates.contains(dateKey)) {
        final sample = await getVitalSample(patientId, date);
        if (sample != null) {
          samples.add(sample);
          addedDates.add(dateKey);
        }
      }
    }
    
    return samples;
  }

  // 取得近期的生命跡象資料（確保每天只有一個數據點）
  Future<List<VitalSample>> getVitalSamplesFirstOnly(String patientId, int days) async {
    // 使用 async 版本
    final samples = await getVitalSamples(patientId, days);
    // 按日期去重，只保留每天的第一個
    final dateMap = <String, VitalSample>{};
    for (final sample in samples) {
      final dateKey = '${sample.timestamp.year}-${sample.timestamp.month}-${sample.timestamp.day}';
      if (!dateMap.containsKey(dateKey)) {
        dateMap[dateKey] = sample;
      }
    }
    return dateMap.values.toList()..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  // 取得特定日期的服藥紀錄
  List<IntakeRecord> getIntakeRecords(String patientId, DateTime date) {
    final dateKey = '${date.year}-${date.month}-${date.day}';
    
    if (!_recordsCache.containsKey(patientId)) {
      _recordsCache[patientId] = {};
    }
    
    if (!_recordsCache[patientId]!.containsKey(dateKey)) {
      final medications = getMedications(patientId);
      _recordsCache[patientId]![dateKey] = RandomDataService.generateIntakeRecords(patientId, date, medications);
    }
    
    return _recordsCache[patientId]![dateKey]!;
  }

  // 取得日期範圍的服藥紀錄
  List<IntakeRecord> getIntakeRecordsRange(String patientId, DateTime startDate, DateTime endDate) {
    final records = <IntakeRecord>[];
    DateTime currentDate = startDate;
    
    while (currentDate.isBefore(endDate) || currentDate.isAtSameMomentAs(endDate)) {
      records.addAll(getIntakeRecords(patientId, currentDate));
      currentDate = currentDate.add(Duration(days: 1));
    }
    
    return records;
  }

  // 取得特定日期的環境讀數（從 API 獲取）
  Future<List<EnvReading>> getEnvReadings(String patientId, DateTime date) async {
    final dateKey = '${date.year}-${date.month}-${date.day}';
    
    // 檢查緩存
    if (_envCache.containsKey(patientId) && 
        _envCache[patientId]!.containsKey(dateKey)) {
      return _envCache[patientId]![dateKey]!;
    }

    // 嘗試從 API 獲取
    final userId = ApiDataMapper.patientIdToUserId(patientId);
    if (userId != null) {
      try {
        // 獲取歷史數據，找到對應日期的數據
        final history = await _apiService.getHistoryData(userId, limit: 100);
        final readings = <EnvReading>[];
        
        for (final record in history) {
          final recordTimestamp = DateTime.parse(record['timestamp'] as String);
          final recordDateKey = '${recordTimestamp.year}-${recordTimestamp.month}-${recordTimestamp.day}';
          
          if (recordDateKey == dateKey) {
            final reading = ApiDataMapper.envReadingFromApiData(record);
            if (reading != null) {
              readings.add(reading);
            }
          }
        }
        
        if (readings.isNotEmpty) {
          // 緩存結果
          if (!_envCache.containsKey(patientId)) {
            _envCache[patientId] = {};
          }
          _envCache[patientId]![dateKey] = readings;
          return readings;
        }
      } catch (e) {
        print('無法從 API 獲取環境讀數: $e');
      }
    }

    // 如果 API 沒有數據或失敗，使用隨機數據
    if (!_envCache.containsKey(patientId)) {
      _envCache[patientId] = {};
    }
    _envCache[patientId]![dateKey] = RandomDataService.generateEnvReadings(patientId, date);
    return _envCache[patientId]![dateKey]!;
  }

  // 同步版本（為了向後兼容）
  List<EnvReading> getEnvReadingsSync(String patientId, DateTime date) {
    final dateKey = '${date.year}-${date.month}-${date.day}';
    
    if (!_envCache.containsKey(patientId)) {
      _envCache[patientId] = {};
    }
    
    if (!_envCache[patientId]!.containsKey(dateKey)) {
      _envCache[patientId]![dateKey] = RandomDataService.generateEnvReadings(patientId, date);
    }
    
    return _envCache[patientId]![dateKey]!;
  }

  // 取得日期範圍的環境讀數（同步版本，使用緩存）
  List<EnvReading> getEnvReadingsRange(String patientId, DateTime startDate, DateTime endDate) {
    final readings = <EnvReading>[];
    DateTime currentDate = startDate;
    
    while (currentDate.isBefore(endDate) || currentDate.isAtSameMomentAs(endDate)) {
      readings.addAll(getEnvReadingsSync(patientId, currentDate));
      currentDate = currentDate.add(Duration(days: 1));
    }
    
    return readings;
  }

  // 取得日期範圍的環境讀數（每天只取第一個數據點，同步版本）
  List<EnvReading> getEnvReadingsRangeFirstOnly(String patientId, DateTime startDate, DateTime endDate) {
    final readings = <EnvReading>[];
    DateTime currentDate = startDate;
    
    while (currentDate.isBefore(endDate) || currentDate.isAtSameMomentAs(endDate)) {
      final dayReadings = getEnvReadingsSync(patientId, currentDate);
      if (dayReadings.isNotEmpty) {
        // 只取每天的第一個數據點
        readings.add(dayReadings.first);
      }
      currentDate = currentDate.add(Duration(days: 1));
    }
    
    return readings;
  }

  // 取得通知
  List<Map<String, dynamic>> getNotifications(String patientId) {
    if (!_notificationsCache.containsKey(patientId)) {
      _notificationsCache[patientId] = RandomDataService.generateNotifications(patientId);
    }
    return _notificationsCache[patientId]!;
  }

  // 標記通知為已讀
  void markNotificationAsRead(String patientId, String notificationId) {
    final notifications = getNotifications(patientId);
    final notification = notifications.firstWhere(
      (n) => n['id'] == notificationId,
      orElse: () => {},
    );
    if (notification.isNotEmpty) {
      notification['isRead'] = true;
    }
  }

  // 清除所有通知
  void clearAllNotifications(String patientId) {
    _notificationsCache[patientId] = [];
  }

  // 重新產生當天的生命跡象（用於手動刷新，從 API 獲取最新數據）
  Future<VitalSample> refreshTodayVitals(String patientId) async {
    final today = DateTime.now();
    final dateKey = '${today.year}-${today.month}-${today.day}';
    
    // 清除當天的緩存
    if (_vitalsCache.containsKey(patientId)) {
      _vitalsCache[patientId]!.remove(dateKey);
    }

    // 嘗試從 API 獲取最新數據
    final userId = ApiDataMapper.patientIdToUserId(patientId);
    if (userId != null) {
      try {
        final latest = await _apiService.getLatestData(userId);
        if (latest != null) {
          final vital = ApiDataMapper.vitalSampleFromApiData(latest);
          if (vital != null) {
            // 檢查是否為今天的數據
            final latestDate = vital.timestamp;
            final latestDateKey = '${latestDate.year}-${latestDate.month}-${latestDate.day}';
            if (latestDateKey == dateKey) {
              if (!_vitalsCache.containsKey(patientId)) {
                _vitalsCache[patientId] = {};
              }
              _vitalsCache[patientId]![dateKey] = vital;
              return vital;
            }
          }
        }
      } catch (e) {
        print('無法從 API 刷新生命跡象: $e');
      }
    }

    // 如果 API 沒有數據或失敗，使用隨機數據
    if (!_vitalsCache.containsKey(patientId)) {
      _vitalsCache[patientId] = {};
    }
    _vitalsCache[patientId]![dateKey] = RandomDataService.generateVitalSample(patientId, today);
    return _vitalsCache[patientId]![dateKey]!;
  }

  // 取得今日用藥摘要
  Map<String, int> getTodayMedicationSummary(String patientId) {
    final today = DateTime.now();
    final records = getIntakeRecords(patientId, today);
    
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
    };
  }

  // 取得服藥依從性統計
  Map<String, int> getMedicationCompliance(String patientId, int days) {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));
    final records = getIntakeRecordsRange(patientId, startDate, endDate);
    
    int onTime = 0;
    int total = records.length;
    
    for (final record in records) {
      if (record.status == IntakeStatus.onTime) {
        onTime++;
      }
    }
    
    return {
      'onTime': onTime,
      'total': total,
      'late': records.where((r) => r.status == IntakeStatus.late).length,
      'missed': records.where((r) => r.status == IntakeStatus.missed).length,
    };
  }

  // 取得每日整體服藥狀態（使用同步版本）
  List<DailyMedicationStatus> getDailyMedicationStatus(String patientId, int days) {
    final statusList = <DailyMedicationStatus>[];
    final now = DateTime.now();
    
    // 修改排序邏輯：從今天開始，然後昨天、前天...
    for (int i = 0; i < days; i++) {
      final date = now.subtract(Duration(days: i));
      final records = getIntakeRecords(patientId, date);
      final vitals = getVitalSampleSync(patientId, date);
      
      // 判斷是否有服藥（只要有任何一個藥物被服用就算有服藥）
      bool hasTakenMedication = records.any((record) => 
          record.status == IntakeStatus.onTime || record.status == IntakeStatus.late);
      
      statusList.add(DailyMedicationStatus(
        date: date,
        hasTakenMedication: hasTakenMedication,
        heartRate: vitals?.heartRate,
        spo2: vitals?.spo2,
        measurementTime: vitals?.timestamp,
      ));
    }
    
    return statusList;
  }
}
