import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/medication.dart';
import 'patient_providers.dart';

// 用藥清單 provider
final medicationsProvider = Provider<List<Medication>>((ref) {
  final repository = ref.watch(demoRepositoryProvider);
  final selectedPatient = ref.watch(selectedPatientProvider);
  
  if (selectedPatient == null) return [];
  
  return repository.getMedications(selectedPatient.id);
});

// 按名稱搜尋用藥 provider
final searchMedicationsProvider = Provider.family<List<Medication>, String>((ref, query) {
  final medications = ref.watch(medicationsProvider);
  
  if (query.isEmpty) return medications;
  
  return medications.where((med) => 
    med.name.toLowerCase().contains(query.toLowerCase())
  ).toList();
});

// 按到期日排序用藥 provider
final sortedMedicationsProvider = Provider<List<Medication>>((ref) {
  final medications = ref.watch(medicationsProvider);
  
  return List.from(medications)..sort((a, b) {
    if (a.expiry == null && b.expiry == null) return 0;
    if (a.expiry == null) return 1;
    if (b.expiry == null) return -1;
    return a.expiry!.compareTo(b.expiry!);
  });
});

// 即將到期的用藥 provider (7天內)
final expiringMedicationsProvider = Provider<List<Medication>>((ref) {
  final medications = ref.watch(medicationsProvider);
  final now = DateTime.now();
  
  return medications.where((med) {
    if (med.expiry == null) return false;
    final daysUntilExpiry = med.expiry!.difference(now).inDays;
    return daysUntilExpiry <= 7 && daysUntilExpiry >= 0;
  }).toList();
});

// 已過期的用藥 provider
final expiredMedicationsProvider = Provider<List<Medication>>((ref) {
  final medications = ref.watch(medicationsProvider);
  final now = DateTime.now();
  
  return medications.where((med) {
    if (med.expiry == null) return false;
    return med.expiry!.isBefore(now);
  }).toList();
});
