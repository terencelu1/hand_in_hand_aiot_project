class Patient {
  final String id;
  final String name;
  final String? avatarUrl;

  const Patient({
    required this.id,
    required this.name,
    this.avatarUrl,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }

  /// 從樹莓派 API 使用者資料建立 Patient
  /// API 格式: {"1": {"name": "使用者1號", "relay": 1}, ...}
  factory Patient.fromApiData(String userId, Map<String, dynamic> apiUserData) {
    final name = apiUserData['name'] as String? ?? '使用者$userId';
    // 將 API 的數字 ID 轉換為 Flutter 的字串 ID
    final id = 'patient_$userId';
    
    return Patient(
      id: id,
      name: name,
      avatarUrl: null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatarUrl': avatarUrl,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Patient && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Patient(id: $id, name: $name)';
}
