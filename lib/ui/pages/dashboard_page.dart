import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/patient_providers.dart';
import '../../providers/dashboard_providers.dart';
import '../../providers/notifications_providers.dart';
import '../widgets/vitals_card.dart';
import '../widgets/trend_chart.dart';
import '../widgets/alert_banner.dart';
import '../widgets/section_header.dart';
import '../widgets/liquid_glass_card.dart';
import '../../theme.dart';

class DashboardPage extends HookConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPatient = ref.watch(selectedPatientProvider);
    final todayVitalsAsync = ref.watch(todayVitalsProvider);
    final weeklyVitalsAsync = ref.watch(weeklyVitalsProvider);
    final notifications = ref.watch(sortedNotificationsProvider);
    final refreshVitals = ref.watch(refreshVitalsProvider);
    final chartType = useState(ChartType.heartRate);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          selectedPatient?.name ?? '醫療監控',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          LiquidGlassButton(
            width: 40,
            height: 40,
            padding: EdgeInsets.zero,
            onPressed: () => context.go('/patients'),
            child: Icon(
              Icons.people,
              color: Theme.of(context).colorScheme.onSurface,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          LiquidGlassButton(
            width: 40,
            height: 40,
            padding: EdgeInsets.zero,
            onPressed: () => context.go('/notifications'),
            child: Icon(
              Icons.notifications,
              color: Theme.of(context).colorScheme.onSurface,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: selectedPatient == null
          ? const Center(child: Text('請選擇病人'))
          : RefreshIndicator(
              onRefresh: () async {
                ref.read(refreshVitalsProvider.notifier).refreshTodayVitals();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 病人資訊
                    LiquidGlassCard(
                      margin: const EdgeInsets.all(16),
                      gradientStart: LiquidGlassColors.primaryPurple.withOpacity(0.2),
                      gradientEnd: LiquidGlassColors.accentCyan.withOpacity(0.1),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  LiquidGlassColors.primaryPurple,
                                  LiquidGlassColors.accentCyan,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: LiquidGlassColors.primaryPurple.withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                selectedPatient.name.isNotEmpty 
                                    ? selectedPatient.name[0] 
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 24,
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
                                  selectedPatient.name,
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                Text(
                                  '今日 ${DateTime.now().month}/${DateTime.now().day}',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // 今日生命跡象
                    todayVitalsAsync.when(
                      data: (vitals) => VitalsCard(
                        vitalSample: vitals,
                        onRefresh: () {
                          ref.read(refreshVitalsProvider.notifier).refreshTodayVitals();
                        },
                        isLoading: refreshVitals,
                      ),
                      loading: () => VitalsCard(
                        vitalSample: null,
                        onRefresh: () {
                          ref.read(refreshVitalsProvider.notifier).refreshTodayVitals();
                        },
                        isLoading: true,
                      ),
                      error: (error, stack) => VitalsCard(
                        vitalSample: null,
                        onRefresh: () {
                          ref.read(refreshVitalsProvider.notifier).refreshTodayVitals();
                        },
                        isLoading: false,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // 近7天趨勢圖
                    weeklyVitalsAsync.when(
                      data: (vitals) => TrendChart(
                        data: vitals,
                        type: chartType.value,
                        onTypeChanged: () {
                          chartType.value = chartType.value == ChartType.heartRate
                              ? ChartType.spo2
                              : ChartType.heartRate;
                        },
                      ),
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (error, stack) => Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Text('載入資料時發生錯誤: $error'),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // 警示橫幅
                    if (notifications.isNotEmpty) ...[
                      SectionHeader(
                        title: '警示與提醒',
                        subtitle: '${notifications.length} 則通知',
                        onMorePressed: () => context.go('/notifications'),
                      ),
                      ...notifications.take(3).map((notification) => AlertBanner(
                        title: notification['title'] as String,
                        message: notification['message'] as String,
                        type: notification['type'] as String,
                        onDismiss: () {
                          ref.read(markNotificationReadProvider(notification['id'] as String));
                        },
                      )),
                    ],
                    
                    const SizedBox(height: 80), // 底部導覽列空間
                  ],
                ),
              ),
            ),
    );
  }
}
