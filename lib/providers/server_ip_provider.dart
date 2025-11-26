import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 服务器IP设置的默认值
const String defaultServerIp = '10.23.220.34';
const String serverIpKey = 'server_ip';

// 服务器IP provider
final serverIpProvider = StateNotifierProvider<ServerIpNotifier, String>((ref) {
  return ServerIpNotifier();
});

class ServerIpNotifier extends StateNotifier<String> {
  ServerIpNotifier() : super(defaultServerIp) {
    _loadServerIp();
  }

  void _loadServerIp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedIp = prefs.getString(serverIpKey);
      if (savedIp != null && savedIp.isNotEmpty) {
        state = savedIp;
      }
    } catch (e) {
      // 如果 SharedPreferences 失敗，使用預設值
      state = defaultServerIp;
    }
  }

  void setServerIp(String ip) {
    if (_isValidIp(ip)) {
      state = ip;
      _saveServerIp(ip);
    }
  }

  bool _isValidIp(String ip) {
    // 简单的IP验证：检查是否为空，以及是否包含有效的IP格式
    if (ip.isEmpty) return false;
    
    // 基本的IP格式验证（IPv4）
    final ipRegex = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
    if (!ipRegex.hasMatch(ip)) return false;
    
    // 检查每个数字段是否在0-255范围内
    final parts = ip.split('.');
    if (parts.length != 4) return false;
    
    for (final part in parts) {
      final num = int.tryParse(part);
      if (num == null || num < 0 || num > 255) {
        return false;
      }
    }
    
    return true;
  }

  void _saveServerIp(String ip) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(serverIpKey, ip);
    } catch (e) {
      // 忽略 SharedPreferences 錯誤
    }
  }
}

