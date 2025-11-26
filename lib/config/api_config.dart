class ApiConfig {
  // 樹莓派 IP 地址（預設值）
  static const String defaultServerIp = '10.23.220.34';
  static const int defaultPort = 5000;
  
  // 舊的靜態屬性（向後兼容）
  @Deprecated('使用 defaultServerIp 代替')
  static const String raspberryPiIp = defaultServerIp;
  @Deprecated('使用 defaultPort 代替')
  static const int port = defaultPort;
  
  // 根據IP和端口生成基礎URL
  static String getBaseUrl(String serverIp, int port) {
    return 'http://$serverIp:$port';
  }
  
  // 使用預設值的基礎URL（向後兼容）
  static String get baseUrl => getBaseUrl(defaultServerIp, defaultPort);
  
  // API 端點（使用預設值，向後兼容）
  static String get healthEndpoint => '$baseUrl/api/health';
  static String get statusEndpoint => '$baseUrl/api/status';
  static String get usersEndpoint => '$baseUrl/api/users';
  static String get currentDataEndpoint => '$baseUrl/api/current_data';
  static String get latestEndpoint => '$baseUrl/api/latest';
  static String get historyEndpoint => '$baseUrl/api/history';
  
  // 請求超時時間（秒）
  static const Duration timeout = Duration(seconds: 10);
}

