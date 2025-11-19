class ApiConfig {
  // 樹莓派 IP 地址
  static const String raspberryPiIp = '172.20.10.8';
  static const int port = 5000;
  
  // API 基礎 URL
  static String get baseUrl => 'http://$raspberryPiIp:$port';
  
  // API 端點
  static String get healthEndpoint => '$baseUrl/api/health';
  static String get statusEndpoint => '$baseUrl/api/status';
  static String get usersEndpoint => '$baseUrl/api/users';
  static String get currentDataEndpoint => '$baseUrl/api/current_data';
  static String get latestEndpoint => '$baseUrl/api/latest';
  static String get historyEndpoint => '$baseUrl/api/history';
  
  // 請求超時時間（秒）
  static const Duration timeout = Duration(seconds: 10);
}

