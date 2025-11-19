class EnvReading {
  final DateTime timestamp;
  final double tempC;
  final double humidity;
  final bool warn;

  const EnvReading({
    required this.timestamp,
    required this.tempC,
    required this.humidity,
    required this.warn,
  });

  factory EnvReading.fromJson(Map<String, dynamic> json) {
    return EnvReading(
      timestamp: DateTime.parse(json['timestamp'] as String),
      tempC: (json['tempC'] as num).toDouble(),
      humidity: (json['humidity'] as num).toDouble(),
      warn: json['warn'] as bool,
    );
  }

  /// 從樹莓派 API 資料建立 EnvReading
  /// API 欄位: object_temp, ambient_temp, timestamp
  factory EnvReading.fromApiData(Map<String, dynamic> apiData) {
    // 解析時間戳
    DateTime timestamp;
    if (apiData.containsKey('timestamp')) {
      timestamp = DateTime.parse(apiData['timestamp'] as String);
    } else {
      timestamp = DateTime.now();
    }

    // API 提供 object_temp 和 ambient_temp，使用 ambient_temp 作為環境溫度
    final ambientTemp = apiData['ambient_temp'] as double? ?? 
                       (apiData['ambient_temp'] as num?)?.toDouble() ?? 25.0;
    
    // API 沒有 humidity，使用預設值或從其他來源獲取
    // 這裡先使用預設值，如果 API 未來提供 humidity 可以更新
    final humidity = apiData['humidity'] as double? ?? 
                    (apiData['humidity'] as num?)?.toDouble() ?? 50.0;

    // 判斷是否需要警告（溫度過高或過低）
    final warn = ambientTemp > 28 || ambientTemp < 20;

    return EnvReading(
      timestamp: timestamp,
      tempC: ambientTemp,
      humidity: humidity,
      warn: warn,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'tempC': tempC,
      'humidity': humidity,
      'warn': warn,
    };
  }

  @override
  String toString() => 'EnvReading(timestamp: $timestamp, tempC: ${tempC}°C, humidity: ${humidity}%, warn: $warn)';
}
