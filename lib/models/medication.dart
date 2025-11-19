class Medication {
  final String id;
  final String name;
  final String dose;
  final String schedule;
  final String? rfidTag;
  final DateTime? expiry;

  const Medication({
    required this.id,
    required this.name,
    required this.dose,
    required this.schedule,
    this.rfidTag,
    this.expiry,
  });

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id: json['id'] as String,
      name: json['name'] as String,
      dose: json['dose'] as String,
      schedule: json['schedule'] as String,
      rfidTag: json['rfidTag'] as String?,
      expiry: json['expiry'] != null ? DateTime.parse(json['expiry'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dose': dose,
      'schedule': schedule,
      'rfidTag': rfidTag,
      'expiry': expiry?.toIso8601String(),
    };
  }

  int? get daysUntilExpiry {
    if (expiry == null) return null;
    final now = DateTime.now();
    final difference = expiry!.difference(now).inDays;
    return difference >= 0 ? difference : 0;
  }

  @override
  String toString() => 'Medication(id: $id, name: $name, dose: $dose, schedule: $schedule)';
}
