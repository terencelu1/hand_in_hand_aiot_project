enum IntakeStatus {
  onTime,
  late,
  missed,
}

enum VerificationMethod {
  fingerprint,
  vision,
  none,
}

class IntakeRecord {
  final DateTime timestamp;
  final IntakeStatus status;
  final VerificationMethod verifiedBy;
  final String medicationId;
  final String medicationName;
  final String dose;
  final int? heartRate;
  final int? spo2;
  final String? notes;

  const IntakeRecord({
    required this.timestamp,
    required this.status,
    required this.verifiedBy,
    required this.medicationId,
    required this.medicationName,
    required this.dose,
    this.heartRate,
    this.spo2,
    this.notes,
  });

  factory IntakeRecord.fromJson(Map<String, dynamic> json) {
    return IntakeRecord(
      timestamp: DateTime.parse(json['timestamp'] as String),
      status: IntakeStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => IntakeStatus.missed,
      ),
      verifiedBy: VerificationMethod.values.firstWhere(
        (e) => e.name == json['verifiedBy'],
        orElse: () => VerificationMethod.none,
      ),
      medicationId: json['medicationId'] as String,
      medicationName: json['medicationName'] as String,
      dose: json['dose'] as String,
      heartRate: json['heartRate'] as int?,
      spo2: json['spo2'] as int?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'status': status.name,
      'verifiedBy': verifiedBy.name,
      'medicationId': medicationId,
      'medicationName': medicationName,
      'dose': dose,
      'heartRate': heartRate,
      'spo2': spo2,
      'notes': notes,
    };
  }

  @override
  String toString() => 'IntakeRecord(timestamp: $timestamp, status: $status, medication: $medicationName)';
}
