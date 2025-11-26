import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/patient.dart';
import '../services/demo_repository.dart';
import '../services/raspberry_pi_api_service.dart';
import '../config/api_config.dart';
import 'server_ip_provider.dart';

// Repository provider
final demoRepositoryProvider = Provider<DemoRepository>((ref) {
  final serverIp = ref.watch(serverIpProvider);
  final apiService = RaspberryPiApiService(
    serverIp: serverIp,
    port: ApiConfig.defaultPort,
  );
  return DemoRepository(apiService: apiService);
});

// 所有病人 provider（使用 FutureProvider 支援 async）
final patientsProvider = FutureProvider<List<Patient>>((ref) async {
  final repository = ref.watch(demoRepositoryProvider);
  return await repository.getAllPatients();
});

// 當前選擇的病人 provider
final selectedPatientProvider = StateNotifierProvider<SelectedPatientNotifier, Patient?>((ref) {
  return SelectedPatientNotifier();
});

class SelectedPatientNotifier extends StateNotifier<Patient?> {
  SelectedPatientNotifier() : super(null) {
    _loadSelectedPatient();
  }

  void _loadSelectedPatient() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final patientId = prefs.getString('selected_patient_id');
      
      final repository = DemoRepository();
      final patients = await repository.getAllPatients();
      
      if (patientId != null) {
        final patient = patients.firstWhere(
          (p) => p.id == patientId,
          orElse: () => patients.isNotEmpty ? patients.first : throw StateError('No patients'),
        );
        state = patient;
      } else {
        // 預設選擇第一個病人
        if (patients.isNotEmpty) {
          state = patients.first;
          _saveSelectedPatient(patients.first.id);
        }
      }
    } catch (e) {
      // 如果失敗，嘗試使用同步方法
      try {
        final repository = DemoRepository();
        final patients = repository.getAllPatientsSync();
        if (patients.isNotEmpty) {
          state = patients.first;
        }
      } catch (e2) {
        // 忽略錯誤
      }
    }
  }

  void selectPatient(Patient patient) {
    state = patient;
    _saveSelectedPatient(patient.id);
  }

  void _saveSelectedPatient(String patientId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_patient_id', patientId);
    } catch (e) {
      // 忽略 SharedPreferences 錯誤
    }
  }
}
