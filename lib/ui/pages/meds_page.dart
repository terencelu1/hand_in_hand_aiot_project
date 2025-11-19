import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../providers/patient_providers.dart';
import '../../providers/meds_providers.dart';
import '../widgets/medication_tile.dart';

class MedsPage extends HookConsumerWidget {
  const MedsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPatient = ref.watch(selectedPatientProvider);
    final medications = ref.watch(sortedMedicationsProvider);
    final expiringMeds = ref.watch(expiringMedicationsProvider);
    final expiredMeds = ref.watch(expiredMedicationsProvider);
    final searchQuery = useState('');
    final searchResults = ref.watch(searchMedicationsProvider(searchQuery.value));

    return Scaffold(
      appBar: AppBar(
        title: const Text('藥品管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(context, searchQuery),
            tooltip: '搜尋',
          ),
        ],
      ),
      body: selectedPatient == null
          ? const Center(child: Text('請選擇病人'))
          : medications.isEmpty
              ? _buildEmptyState(context)
              : Column(
                  children: [
                    // 警示區塊
                    if (expiredMeds.isNotEmpty || expiringMeds.isNotEmpty) ...[
                      _buildAlertSection(context, expiredMeds, expiringMeds),
                    ],
                    
                    // 藥品清單
                    Expanded(
                      child: ListView.builder(
                        itemCount: searchQuery.value.isEmpty 
                            ? medications.length 
                            : searchResults.length,
                        itemBuilder: (context, index) {
                          final medication = searchQuery.value.isEmpty 
                              ? medications[index] 
                              : searchResults[index];
                          final hasWarning = expiredMeds.contains(medication) || 
                                           expiringMeds.contains(medication);
                          
                          return MedicationTile(
                            medication: medication,
                            hasWarning: hasWarning,
                            onTap: () => _showMedicationDetails(context, medication),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.medication_outlined,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            '暫無用藥資料',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '請聯繫醫療人員添加用藥資訊',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertSection(
    BuildContext context,
    List expiredMeds,
    List expiringMeds,
  ) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.error.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(width: 8),
              Text(
                '藥品警示',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (expiredMeds.isNotEmpty) ...[
            Text(
              '已過期: ${expiredMeds.length} 種',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
          if (expiringMeds.isNotEmpty) ...[
            Text(
              '即將到期: ${expiringMeds.length} 種',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showSearchDialog(BuildContext context, ValueNotifier<String> searchQuery) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('搜尋藥品'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '輸入藥品名稱',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            searchQuery.value = value;
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              searchQuery.value = '';
              Navigator.pop(context);
            },
            child: const Text('清除'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('關閉'),
          ),
        ],
      ),
    );
  }

  void _showMedicationDetails(BuildContext context, medication) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(medication.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('劑量: ${medication.dose}'),
            Text('服用時間: ${medication.schedule}'),
            if (medication.rfidTag != null) Text('RFID: ${medication.rfidTag}'),
            if (medication.expiry != null) 
              Text('到期日: ${medication.expiry.toString().split(' ')[0]}'),
            if (medication.daysUntilExpiry != null) 
              Text('剩餘天數: ${medication.daysUntilExpiry} 天'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('關閉'),
          ),
        ],
      ),
    );
  }
}
