import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

/// 樹莓派 API 服務
class RaspberryPiApiService {
  static const Duration timeout = Duration(seconds: 10);

  final http.Client _client;
  final String _serverIp;
  final int _port;

  RaspberryPiApiService({
    http.Client? client,
    String? serverIp,
    int? port,
  })  : _client = client ?? http.Client(),
        _serverIp = serverIp ?? ApiConfig.defaultServerIp,
        _port = port ?? ApiConfig.defaultPort;

  String get baseUrl => 'http://$_serverIp:$_port';

  /// 健康檢查
  Future<bool> checkHealth() async {
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/api/health'))
          .timeout(timeout);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// 獲取系統狀態
  Future<Map<String, dynamic>?> getStatus() async {
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/api/status'))
          .timeout(timeout);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          return data['status'] as Map<String, dynamic>?;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// 獲取使用者列表
  /// 返回: { "1": {"name": "...", "relay": 1}, ... }
  Future<Map<String, Map<String, dynamic>>?> getUsers() async {
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/api/users'))
          .timeout(timeout);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        if (data['success'] == true && data['data'] != null) {
          final usersData = data['data'] as Map<String, dynamic>;
          final result = <String, Map<String, dynamic>>{};
          
          usersData.forEach((key, value) {
            result[key] = value as Map<String, dynamic>;
          });
          
          return result;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// 獲取當前感測器數據（待機模式）
  Future<Map<String, dynamic>?> getCurrentData() async {
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/api/current_data'))
          .timeout(timeout);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        if (data['success'] == true && data['data'] != null) {
          return data['data'] as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// 獲取指定使用者的最新測量數據
  /// userId: 使用者 ID（整數）
  Future<Map<String, dynamic>?> getLatestData(int userId) async {
    try {
      final uri = Uri.parse('$baseUrl/api/latest').replace(
        queryParameters: {'user_id': userId.toString()},
      );
      
      final response = await _client.get(uri).timeout(timeout);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        if (data['success'] == true && data['data'] != null) {
          return data['data'] as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// 獲取指定使用者的歷史測量數據
  /// userId: 使用者 ID（整數）
  /// limit: 返回記錄數量限制（預設：100）
  Future<List<Map<String, dynamic>>> getHistoryData(int userId, {int limit = 100}) async {
    try {
      final uri = Uri.parse('$baseUrl/api/history').replace(
        queryParameters: {
          'user_id': userId.toString(),
          'limit': limit.toString(),
        },
      );
      
      final response = await _client.get(uri).timeout(timeout);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        if (data['success'] == true && data['data'] != null) {
          final list = data['data'] as List<dynamic>;
          return list.map((item) => item as Map<String, dynamic>).toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// 將 API 的 user_id（整數）轉換為 Flutter 的 patient_id（字串）
  static String userIdToPatientId(int userId) {
    return 'patient_$userId';
  }

  /// 將 Flutter 的 patient_id（字串）轉換為 API 的 user_id（整數）
  static int? patientIdToUserId(String patientId) {
    if (patientId.startsWith('patient_')) {
      final idStr = patientId.substring('patient_'.length);
      return int.tryParse(idStr);
    }
    return null;
  }
}
