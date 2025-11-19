class DailyMedicationStatus {
  final DateTime date;
  final bool hasTakenMedication; // 是否有服藥（整體狀態）
  final int? heartRate; // 當日心率
  final int? spo2; // 當日血氧
  final DateTime? measurementTime; // 測量時間

  const DailyMedicationStatus({
    required this.date,
    required this.hasTakenMedication,
    this.heartRate,
    this.spo2,
    this.measurementTime,
  });

  factory DailyMedicationStatus.fromJson(Map<String, dynamic> json) {
    return DailyMedicationStatus(
      date: DateTime.parse(json['date'] as String),
      hasTakenMedication: json['hasTakenMedication'] as bool,
      heartRate: json['heartRate'] as int?,
      spo2: json['spo2'] as int?,
      measurementTime: json['measurementTime'] != null 
          ? DateTime.parse(json['measurementTime'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'hasTakenMedication': hasTakenMedication,
      'heartRate': heartRate,
      'spo2': spo2,
      'measurementTime': measurementTime?.toIso8601String(),
    };
  }

  @override
  String toString() => 'DailyMedicationStatus(date: $date, hasTakenMedication: $hasTakenMedication, heartRate: $heartRate, spo2: $spo2)';
}
