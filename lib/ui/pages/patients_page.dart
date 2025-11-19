import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/patient_providers.dart';
import '../../models/patient.dart';
import '../../theme.dart';
import '../widgets/liquid_glass_card.dart';
import '../widgets/liquid_glass_background.dart';

class PatientsPage extends ConsumerWidget {
  const PatientsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientsAsync = ref.watch(patientsProvider);
    final selectedPatient = ref.watch(selectedPatientProvider);

    return LiquidGlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('病人管理'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: patientsAsync.when(
          data: (patients) {
            if (patients.isEmpty) {
              return _buildEmptyState(context);
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: patients.length,
              itemBuilder: (context, index) {
                final patient = patients[index];
                final isSelected = selectedPatient?.id == patient.id;
                
                return _buildPatientCard(context, ref, patient, isSelected);
              },
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '載入病人資料時發生錯誤',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$error',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: LiquidGlassCard(
        margin: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    theme.colorScheme.primary.withOpacity(0.2),
                    theme.colorScheme.primary.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Icon(
                Icons.people_outline,
                size: 48,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '暫無病人資料',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '請聯繫系統管理員添加病人',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientCard(
    BuildContext context,
    WidgetRef ref,
    Patient patient,
    bool isSelected,
  ) {
    final theme = Theme.of(context);
    
    // 根據選擇狀態選擇卡片顏色
    Color gradientStart;
    Color gradientEnd;
    if (isSelected) {
      gradientStart = LiquidGlassColors.primaryPurple.withOpacity(0.3);
      gradientEnd = LiquidGlassColors.accentCyan.withOpacity(0.2);
    } else {
      gradientStart = LiquidGlassColors.glassWhite.withOpacity(0.8);
      gradientEnd = LiquidGlassColors.glassWhite.withOpacity(0.4);
    }
    
    return LiquidGlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      gradientStart: gradientStart,
      gradientEnd: gradientEnd,
      child: InkWell(
        onTap: () {
          ref.read(selectedPatientProvider.notifier).selectPatient(patient);
          // 使用 go_router 導航而不是 Navigator.pop
          context.go('/');
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      isSelected 
                          ? LiquidGlassColors.primaryPurple.withOpacity(0.3)
                          : theme.colorScheme.primary.withOpacity(0.2),
                      isSelected 
                          ? LiquidGlassColors.accentCyan.withOpacity(0.2)
                          : theme.colorScheme.primary.withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: isSelected 
                      ? LiquidGlassColors.primaryPurple
                      : theme.colorScheme.primary,
                  child: Text(
                    patient.name.isNotEmpty ? patient.name[0] : '?',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isSelected 
                            ? LiquidGlassColors.primaryPurple
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${patient.id}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '最近量測: ${_getLastMeasurementText(ref, patient)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        LiquidGlassColors.primaryPurple.withOpacity(0.3),
                        LiquidGlassColors.accentCyan.withOpacity(0.2),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: LiquidGlassColors.primaryPurple,
                    size: 20,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getLastMeasurementText(WidgetRef ref, Patient patient) {
    // 這裡可以根據實際需求獲取最後量測時間
    // 目前返回模擬數據
    return '今日 12:00';
  }
}
