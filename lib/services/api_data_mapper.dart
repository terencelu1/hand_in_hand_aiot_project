import '../models/patient.dart';
import '../models/vital_sample.dart';
import '../models/env_reading.dart';
import 'raspberry_pi_api_service.dart';

/// API 資料轉換器
/// 負責將樹莓派 API 的資料格式轉換為 Flutter 應用程式使用的模型
class ApiDataMapper {
  /// 將 API 的使用者資料轉換為 Patient
  static Patient patientFromApiData(String userId, Map<String, dynamic> apiUserData) {
    return Patient.fromApiData(userId, apiUserData);
  }

  /// 將 API 的測量資料轉換為 VitalSample
  static VitalSample? vitalSampleFromApiData(Map<String, dynamic> apiData) {
    try {
      // 檢查是否有必要的資料
      if (apiData['heart_rate'] == null && apiData['heartRate'] == null) {
        return null;
      }
      if (apiData['spo2'] == null) {
        return null;
      }

      return VitalSample.fromApiData(apiData);
    } catch (e) {
      print('轉換 VitalSample 時發生錯誤: $e');
      return null;
    }
  }

  /// 將 API 的測量資料轉換為 EnvReading
  static EnvReading? envReadingFromApiData(Map<String, dynamic> apiData) {
    try {
      // 檢查是否有必要的資料
      if (apiData['ambient_temp'] == null && apiData['object_temp'] == null) {
        return null;
      }

      return EnvReading.fromApiData(apiData);
    } catch (e) {
      print('轉換 EnvReading 時發生錯誤: $e');
      return null;
    }
  }

  /// 將 Flutter 的 patient_id 轉換為 API 的 user_id
  static int? patientIdToUserId(String patientId) {
    return RaspberryPiApiService.patientIdToUserId(patientId);
  }

  /// 將 API 的 user_id 轉換為 Flutter 的 patient_id
  static String userIdToPatientId(int userId) {
    return RaspberryPiApiService.userIdToPatientId(userId);
  }
}
