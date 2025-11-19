class VitalSample {
  final DateTime timestamp;
  final int heartRate;
  final int spo2;
  final double quality;

  const VitalSample({
    required this.timestamp,
    required this.heartRate,
    required this.spo2,
    required this.quality,
  });

  factory VitalSample.fromJson(Map<String, dynamic> json) {
    return VitalSample(
      timestamp: DateTime.parse(json['timestamp'] as String),
      heartRate: json['heartRate'] as int,
      spo2: json['spo2'] as int,
      quality: (json['quality'] as num).toDouble(),
    );
  }

  /// 從樹莓派 API 資料建立 VitalSample
  /// API 欄位: heart_rate, spo2, timestamp
  factory VitalSample.fromApiData(Map<String, dynamic> apiData) {
    // 解析時間戳（可能是 ISO 格式或 timestamp_readable）
    DateTime timestamp;
    if (apiData.containsKey('timestamp')) {
      timestamp = DateTime.parse(apiData['timestamp'] as String);
    } else {
      // 如果沒有 timestamp，使用當前時間
      timestamp = DateTime.now();
    }

    // API 使用 heart_rate，Flutter 使用 heartRate
    final heartRate = apiData['heart_rate'] as int? ?? apiData['heartRate'] as int? ?? 0;
    final spo2 = apiData['spo2'] as int? ?? 0;

    // API 沒有 quality 欄位，根據 heart_rate 和 spo2 計算一個合理的 quality
    // 正常範圍內的值給予較高的 quality
    double quality = 0.8;
    if (heartRate >= 60 && heartRate <= 100 && spo2 >= 95 && spo2 <= 100) {
      quality = 0.95;
    } else if (heartRate >= 50 && heartRate <= 120 && spo2 >= 90 && spo2 <= 100) {
      quality = 0.85;
    }

    return VitalSample(
      timestamp: timestamp,
      heartRate: heartRate,
      spo2: spo2,
      quality: quality,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'heartRate': heartRate,
      'spo2': spo2,
      'quality': quality,
    };
  }

  @override
  String toString() => 'VitalSample(timestamp: $timestamp, heartRate: $heartRate, spo2: $spo2, quality: $quality)';
}
