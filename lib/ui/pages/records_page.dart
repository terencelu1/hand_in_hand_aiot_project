import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import '../../providers/patient_providers.dart';
import '../../providers/records_providers.dart';
import '../../models/daily_medication_status.dart';
import '../../theme.dart';
import '../widgets/liquid_glass_card.dart';
import '../widgets/liquid_glass_background.dart';

class RecordsPage extends HookConsumerWidget {
  const RecordsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPatient = ref.watch(selectedPatientProvider);
    final dailyStatus = ref.watch(dailyMedicationStatusProvider(30)); // 最近30天
    final selectedDays = useState(30);

    return LiquidGlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('服藥紀錄'),
          actions: [
            LiquidGlassButton(
              width: 40,
              height: 40,
              padding: EdgeInsets.zero,
              onPressed: () => _showFilterDialog(context, ref, selectedDays),
              child: Icon(
                Icons.filter_list,
                color: Theme.of(context).colorScheme.onSurface,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: selectedPatient == null
            ? const Center(child: Text('請選擇病人'))
            : dailyStatus.isEmpty
                ? _buildEmptyState(context)
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: dailyStatus.length,
                    itemBuilder: (context, index) {
                      final status = dailyStatus[index];
                      return _buildDailyStatusCard(context, status);
                    },
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
                Icons.assignment_outlined,
                size: 48,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '暫無服藥紀錄',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '開始記錄您的服藥情況',
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

  Widget _buildDailyStatusCard(BuildContext context, DailyMedicationStatus status) {
    final theme = Theme.of(context);
    final dateStr = DateFormat('MM月dd日 EEEE', 'zh_TW').format(status.date);
    final isToday = _isToday(status.date);
    
    // 根據服藥狀態選擇卡片顏色
    Color gradientStart;
    Color gradientEnd;
    if (isToday) {
      gradientStart = LiquidGlassColors.primaryPurple.withOpacity(0.3);
      gradientEnd = LiquidGlassColors.accentCyan.withOpacity(0.2);
    } else if (status.hasTakenMedication) {
      gradientStart = LiquidGlassColors.glassWhite.withOpacity(0.8);
      gradientEnd = LiquidGlassColors.glassWhite.withOpacity(0.4);
    } else {
      gradientStart = LiquidGlassColors.accentPink.withOpacity(0.2);
      gradientEnd = LiquidGlassColors.accentPink.withOpacity(0.1);
    }
    
    return LiquidGlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      gradientStart: gradientStart,
      gradientEnd: gradientEnd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 日期標題
          Row(
            children: [
              Expanded(
                child: Text(
                  dateStr,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isToday ? LiquidGlassColors.primaryPurple : theme.colorScheme.onSurface,
                  ),
                ),
              ),
              if (isToday) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        LiquidGlassColors.primaryPurple,
                        LiquidGlassColors.accentCyan,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: LiquidGlassColors.primaryPurple.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '今日',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
            
          const SizedBox(height: 12),
          
          // 服藥狀態
          Row(
            children: [
              Icon(
                status.hasTakenMedication ? Icons.check_circle : Icons.cancel,
                color: status.hasTakenMedication ? StatusColors.success : StatusColors.error,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                status.hasTakenMedication ? '已服藥' : '未服藥',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: status.hasTakenMedication ? StatusColors.success : StatusColors.error,
                ),
              ),
            ],
          ),
            
          // 生命跡象數據
          if (status.heartRate != null || status.spo2 != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    LiquidGlassColors.glassWhite.withOpacity(0.3),
                    LiquidGlassColors.glassWhite.withOpacity(0.1),
                  ],
                ),
                border: Border.all(
                  color: LiquidGlassColors.glassBorder.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  if (status.heartRate != null) ...[
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            ChartColors.heartRate.withOpacity(0.3),
                            ChartColors.heartRate.withOpacity(0.1),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Icon(
                        Icons.favorite, 
                        size: 16, 
                        color: ChartColors.heartRate,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '心率 ${status.heartRate} bpm',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  if (status.spo2 != null) ...[
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            ChartColors.spo2.withOpacity(0.3),
                            ChartColors.spo2.withOpacity(0.1),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Icon(
                        Icons.air, 
                        size: 16, 
                        color: ChartColors.spo2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '血氧 ${status.spo2}%',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
            
          // 測量時間
          if (status.measurementTime != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  '測量時間: ${DateFormat('HH:mm').format(status.measurementTime!)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && 
           date.month == now.month && 
           date.day == now.day;
  }

  void _showFilterDialog(BuildContext context, WidgetRef ref, ValueNotifier<int> selectedDays) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        contentPadding: EdgeInsets.zero,
        content: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: LiquidGlassColors.glassShadow,
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: Theme.of(context).brightness == Brightness.dark
                        ? [
                            LiquidGlassColors.glassDark,
                            LiquidGlassColors.glassDark.withOpacity(0.8),
                          ]
                        : [
                            LiquidGlassColors.glassWhite,
                            LiquidGlassColors.glassWhite.withOpacity(0.8),
                          ],
                  ),
                  border: Border.all(
                    color: LiquidGlassColors.glassBorder,
                    width: 1.5,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '選擇時間範圍',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildFilterOption(context, '最近7天', 7, selectedDays.value, (value) {
                        selectedDays.value = value;
                      }),
                      _buildFilterOption(context, '最近30天', 30, selectedDays.value, (value) {
                        selectedDays.value = value;
                      }),
                      _buildFilterOption(context, '最近90天', 90, selectedDays.value, (value) {
                        selectedDays.value = value;
                      }),
                      const SizedBox(height: 16),
                      LiquidGlassButton(
                        onPressed: () => Navigator.pop(context),
                        gradientStart: LiquidGlassColors.primaryPurple,
                        gradientEnd: LiquidGlassColors.accentCyan,
                        child: const Text(
                          '確定',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterOption(BuildContext context, String title, int value, int selectedValue, Function(int) onChanged) {
    final isSelected = value == selectedValue;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Text(
          title,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected 
                  ? LiquidGlassColors.primaryPurple
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              width: 2,
            ),
            color: isSelected 
                ? LiquidGlassColors.primaryPurple
                : Colors.transparent,
          ),
          child: isSelected
              ? const Icon(
                  Icons.check,
                  size: 12,
                  color: Colors.white,
                )
              : null,
        ),
        onTap: () => onChanged(value),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}