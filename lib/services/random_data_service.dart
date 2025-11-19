import 'dart:math';
import '../models/patient.dart';
import '../models/vital_sample.dart';
import '../models/medication.dart';
import '../models/intake_record.dart';
import '../models/env_reading.dart';

class RandomDataService {
  
  // 預設病人資料
  static const List<Patient> _defaultPatients = [
    Patient(id: 'patient_1', name: '示範1'),
    Patient(id: 'patient_2', name: '示範2'),
    Patient(id: 'patient_3', name: '示範3'),
  ];

  static List<Patient> getDefaultPatients() => _defaultPatients;

  // 為每個病人建立固定的隨機種子
  static int _getPatientSeed(String patientId) {
    return patientId.hashCode;
  }

  // 為特定日期建立種子
  static int _getDateSeed(String patientId, DateTime date) {
    final dateStr = '${date.year}-${date.month}-${date.day}';
    return (patientId + dateStr).hashCode;
  }

  // 產生生命跡象資料
  static VitalSample generateVitalSample(String patientId, DateTime date) {
    final seed = _getDateSeed(patientId, date);
    final random = Random(seed);
    
    // 時間 = 當日 12:00 ± 20 分鐘
    final baseTime = DateTime(date.year, date.month, date.day, 12, 0);
    final timeOffset = random.nextInt(41) - 20; // -20 到 +20 分鐘
    final timestamp = baseTime.add(Duration(minutes: timeOffset));
    
    // heartRate 正常分佈均值 75 bpm（±10）
    final heartRate = 75 + (random.nextDouble() * 20 - 10).round();
    
    // spo2 均值 97%（±2）
    final spo2 = 97 + (random.nextDouble() * 4 - 2).round();
    
    // quality 0–1 之間
    final quality = random.nextDouble();
    
    return VitalSample(
      timestamp: timestamp,
      heartRate: heartRate.clamp(60, 120),
      spo2: spo2.clamp(90, 100),
      quality: quality,
    );
  }

  // 產生用藥清單
  static List<Medication> generateMedications(String patientId) {
    final seed = _getPatientSeed(patientId);
    final random = Random(seed);
    
    final medicationNames = [
      '降血壓藥', '維生素D', '鈣片', '魚油', '葉酸', '維生素B12'
    ];
    
    final doses = ['1顆', '2顆', '1粒', '1錠', '1包'];
    final schedules = ['早餐後', '晚餐後', '睡前', '飯前30分鐘', '飯後30分鐘'];
    
    final count = 2 + random.nextInt(2); // 2-3 種藥
    final medications = <Medication>[];
    
    for (int i = 0; i < count; i++) {
      final name = medicationNames[random.nextInt(medicationNames.length)];
      final dose = doses[random.nextInt(doses.length)];
      final schedule = schedules[random.nextInt(schedules.length)];
      
      // 隨機設定到期日（30-365天後）
      final expiryDays = 30 + random.nextInt(335);
      final expiry = DateTime.now().add(Duration(days: expiryDays));
      
      medications.add(Medication(
        id: 'med_${patientId}_$i',
        name: name,
        dose: dose,
        schedule: schedule,
        rfidTag: random.nextBool() ? 'RFID_${random.nextInt(10000)}' : null,
        expiry: expiry,
      ));
    }
    
    return medications;
  }

  // 產生服藥紀錄
  static List<IntakeRecord> generateIntakeRecords(String patientId, DateTime date, List<Medication> medications) {
    final seed = _getDateSeed(patientId, date);
    final random = Random(seed);
    
    final records = <IntakeRecord>[];
    
    for (final medication in medications) {
      // 每天只生成一次服藥紀錄（中午12:00）
      final intakeTime = DateTime(date.year, date.month, date.day, 12, 0);
      
      // status 以 80% 準時、15% 延遲、5% 未服隨機
      final statusRand = random.nextDouble();
      IntakeStatus status;
      if (statusRand < 0.8) {
        status = IntakeStatus.onTime;
      } else if (statusRand < 0.95) {
        status = IntakeStatus.late;
      } else {
        status = IntakeStatus.missed;
      }
      
      // verifiedBy 隨機
      final verificationMethods = VerificationMethod.values;
      final verifiedBy = verificationMethods[random.nextInt(verificationMethods.length)];
      
      // 隨機添加生命跡象資料
      int? heartRate;
      int? spo2;
      if (random.nextBool()) {
        heartRate = (75 + (random.nextDouble() * 20 - 10)).round();
        spo2 = (97 + (random.nextDouble() * 4 - 2)).round();
      }
      
      // 隨機備註
      final notes = random.nextBool() ? _generateRandomNotes(random) : null;
      
      records.add(IntakeRecord(
        timestamp: intakeTime,
        status: status,
        verifiedBy: verifiedBy,
        medicationId: medication.id,
        medicationName: medication.name,
        dose: medication.dose,
        heartRate: heartRate,
        spo2: spo2,
        notes: notes,
      ));
    }
    
    return records;
  }

  // 產生環境讀數
  static List<EnvReading> generateEnvReadings(String patientId, DateTime date) {
    final seed = _getDateSeed(patientId, date);
    final random = Random(seed);
    
    final readings = <EnvReading>[];
    
    // 每日 1 筆（中午12:00）
    final measurementTime = DateTime(date.year, date.month, date.day, 12, 0);
    
    // 溫度 22–29°C
    final tempC = 22 + random.nextDouble() * 7;
    
    // 濕度 45–70%
    final humidity = 45 + random.nextDouble() * 25;
    
    // 偶爾標示 warn=true
    final warn = random.nextDouble() < 0.1; // 10% 機率
    
    readings.add(EnvReading(
      timestamp: measurementTime,
      tempC: tempC,
      humidity: humidity,
      warn: warn,
    ));
    
    return readings;
  }

  // 產生隨機備註
  static String _generateRandomNotes(Random random) {
    final notes = [
      '服藥後感覺良好',
      '無特殊不適',
      '建議調整劑量',
      '需要多喝水',
      '飯後服用效果佳',
      '注意血壓變化',
      '定期檢查肝功能',
    ];
    return notes[random.nextInt(notes.length)];
  }

  // 產生通知資料
  static List<Map<String, dynamic>> generateNotifications(String patientId) {
    final seed = _getPatientSeed(patientId);
    final random = Random(seed);
    
    final notifications = <Map<String, dynamic>>[];
    
    // 藥盒未歸位
    if (random.nextBool()) {
      notifications.add({
        'id': 'notif_1',
        'type': 'warning',
        'title': '藥盒未歸位',
        'message': '請將藥盒放回指定位置',
        'timestamp': DateTime.now().subtract(Duration(hours: 2)),
        'isRead': false,
      });
    }
    
    // 環境溫度偏高
    if (random.nextBool()) {
      notifications.add({
        'id': 'notif_2',
        'type': 'warning',
        'title': '環境溫度偏高',
        'message': '室內溫度超過建議範圍',
        'timestamp': DateTime.now().subtract(Duration(hours: 1)),
        'isRead': false,
      });
    }
    
    // 藥品將於3日後到期
    if (random.nextBool()) {
      notifications.add({
        'id': 'notif_3',
        'type': 'info',
        'title': '藥品即將到期',
        'message': '部分藥品將於3日後到期，請注意補充',
        'timestamp': DateTime.now().subtract(Duration(minutes: 30)),
        'isRead': false,
      });
    }
    
    return notifications;
  }
}
