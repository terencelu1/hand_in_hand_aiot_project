import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/patient_providers.dart';
import '../../providers/dashboard_providers.dart';
import '../../models/vital_sample.dart';
import '../../models/env_reading.dart';
import '../../theme.dart';
import '../widgets/liquid_glass_card.dart';
import '../widgets/liquid_glass_background.dart';

class AnalyticsPage extends HookConsumerWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPatient = ref.watch(selectedPatientProvider);
    final fiveDayVitalsAsync = ref.watch(fiveDayVitalsProvider);
    final weeklyCompliance = ref.watch(medicationComplianceProvider(5));
    final fiveDayEnvReadingsAsync = ref.watch(fiveDayEnvReadingsProvider);
    final selectedChart = useState('vitals');

    return LiquidGlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('數據分析'),
          backgroundColor: Colors.transparent,
        ),
        body: selectedPatient == null
            ? const Center(child: Text('請選擇病人'))
            : SingleChildScrollView(
                child: Column(
                  children: [
                    // 圖表選擇器
                    _buildChartSelector(context, selectedChart),
                    
                    const SizedBox(height: 16),
                    
                    // 生命跡象趨勢
                    if (selectedChart.value == 'vitals')
                      fiveDayVitalsAsync.when(
                        data: (vitals) => Column(
                          children: [
                            _buildHeartRateChart(context, vitals),
                            const SizedBox(height: 16),
                            _buildSpo2Chart(context, vitals),
                            const SizedBox(height: 16),
                          ],
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
                    
                    // 服藥依從性
                    if (selectedChart.value == 'compliance') ...[
                      _buildComplianceChart(context, weeklyCompliance),
                      const SizedBox(height: 16),
                    ],
                    
                    // 環境監測
                    if (selectedChart.value == 'environment')
                      fiveDayEnvReadingsAsync.when(
                        data: (readings) => Column(
                          children: [
                            _buildTemperatureChart(context, readings),
                            const SizedBox(height: 16),
                            _buildHumidityChart(context, readings),
                            const SizedBox(height: 16),
                          ],
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
                    
                    // 統計摘要
                    _buildSummaryCards(context, weeklyCompliance),
                    
                    const SizedBox(height: 80),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildChartSelector(BuildContext context, ValueNotifier<String> selectedChart) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildChartButton(
              context,
              '生命跡象',
              'vitals',
              Icons.favorite,
              selectedChart,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildChartButton(
              context,
              '服藥依從',
              'compliance',
              Icons.medication,
              selectedChart,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildChartButton(
              context,
              '環境監測',
              'environment',
              Icons.thermostat,
              selectedChart,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartButton(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    ValueNotifier<String> selectedChart,
  ) {
    final isSelected = selectedChart.value == value;
    final theme = Theme.of(context);
    
    return LiquidGlassButton(
      onPressed: () => selectedChart.value = value,
      padding: const EdgeInsets.symmetric(vertical: 12),
      gradientStart: isSelected 
          ? LiquidGlassColors.primaryPurple
          : null,
      gradientEnd: isSelected 
          ? LiquidGlassColors.accentCyan
          : null,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected 
                ? Colors.white
                : theme.colorScheme.onSurfaceVariant,
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isSelected 
                  ? Colors.white
                  : theme.colorScheme.onSurfaceVariant,
              fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeartRateChart(BuildContext context, List<VitalSample> vitals) {
    final theme = Theme.of(context);
    
    if (vitals.isEmpty) {
      return _buildEmptyChart(context, '心率趨勢');
    }
    
    final heartRates = vitals.map((v) => v.heartRate.toDouble()).toList();
    final dataMin = heartRates.reduce((a, b) => a < b ? a : b);
    final dataMax = heartRates.reduce((a, b) => a > b ? a : b);
    
    // 使用與 trend_chart 相同的邏輯計算 Y 軸範圍
    final range = dataMax - dataMin;
    final buffer = range < 10 ? 5.0 : range * 0.2;
    
    // 向下取整到最近的 10 的倍數
    double minHeartRate = ((dataMin - buffer) / 10).floor() * 10.0;
    // 向上取整到最近的 10 的倍數
    double maxHeartRate = ((dataMax + buffer) / 10).ceil() * 10.0;
    
    // 確保最小範圍為 30
    if (maxHeartRate - minHeartRate < 30) {
      final center = (minHeartRate + maxHeartRate) / 2;
      minHeartRate = ((center - 15) / 10).floor() * 10.0;
      maxHeartRate = ((center + 15) / 10).ceil() * 10.0;
    }
    
    return LiquidGlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      gradientStart: LiquidGlassColors.accentPink.withOpacity(0.2),
      gradientEnd: LiquidGlassColors.accentPink.withOpacity(0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
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
                  color: ChartColors.heartRate,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '心率趨勢 (近5天)',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: (vitals.length - 1).toDouble(),
                  minY: minHeartRate,
                  maxY: maxHeartRate,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 10,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: theme.colorScheme.outline.withOpacity(0.2),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= vitals.length || index < 0) return const SizedBox.shrink();
                          final sample = vitals[index];
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '${sample.timestamp.month}/${sample.timestamp.day}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 10,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 10,
                        reservedSize: 35,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 10,
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: vitals.asMap().entries.map((e) {
                        return FlSpot(e.key.toDouble(), e.value.heartRate.toDouble());
                      }).toList(),
                      isCurved: true,
                      color: ChartColors.heartRate,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpo2Chart(BuildContext context, List<VitalSample> vitals) {
    final theme = Theme.of(context);
    
    if (vitals.isEmpty) {
      return _buildEmptyChart(context, '血氧趨勢');
    }
    
    final spo2Values = vitals.map((v) => v.spo2.toDouble()).toList();
    final dataMin = spo2Values.reduce((a, b) => a < b ? a : b);
    final dataMax = spo2Values.reduce((a, b) => a > b ? a : b);
    
    // 使用與 trend_chart 相同的邏輯計算 Y 軸範圍
    final range = dataMax - dataMin;
    final buffer = range < 10 ? 5.0 : range * 0.2;
    
    // 向下取整到最近的 10 的倍數
    double minSpo2 = ((dataMin - buffer) / 10).floor() * 10.0;
    // 向上取整到最近的 10 的倍數
    double maxSpo2 = ((dataMax + buffer) / 10).ceil() * 10.0;
    
    // 確保最小範圍為 30
    if (maxSpo2 - minSpo2 < 30) {
      final center = (minSpo2 + maxSpo2) / 2;
      minSpo2 = ((center - 15) / 10).floor() * 10.0;
      maxSpo2 = ((center + 15) / 10).ceil() * 10.0;
    }
    
    return LiquidGlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      gradientStart: LiquidGlassColors.accentCyan.withOpacity(0.2),
      gradientEnd: LiquidGlassColors.accentCyan.withOpacity(0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
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
                  color: ChartColors.spo2,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '血氧趨勢 (近5天)',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: (vitals.length - 1).toDouble(),
                  minY: minSpo2,
                  maxY: maxSpo2,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 10,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: theme.colorScheme.outline.withOpacity(0.2),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= vitals.length || index < 0) return const SizedBox.shrink();
                          final sample = vitals[index];
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '${sample.timestamp.month}/${sample.timestamp.day}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 10,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 10,
                        reservedSize: 35,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 10,
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: vitals.asMap().entries.map((e) {
                        return FlSpot(e.key.toDouble(), e.value.spo2.toDouble());
                      }).toList(),
                      isCurved: true,
                      color: ChartColors.spo2,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComplianceChart(BuildContext context, Map<String, int> compliance) {
    final theme = Theme.of(context);
    
    return LiquidGlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      gradientStart: LiquidGlassColors.primaryPurple.withOpacity(0.2),
      gradientEnd: LiquidGlassColors.primaryPurple.withOpacity(0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      LiquidGlassColors.primaryPurple.withOpacity(0.3),
                      LiquidGlassColors.primaryPurple.withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Icon(
                  Icons.medication,
                  color: LiquidGlassColors.primaryPurple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '服藥依從性 (近5天)',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: compliance['total'] == 0
                ? _buildEmptyChart(context)
                : PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: [
                        PieChartSectionData(
                          color: StatusColors.onTime,
                          value: compliance['onTime']!.toDouble(),
                          title: '準時',
                          radius: 50,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        PieChartSectionData(
                          color: StatusColors.late,
                          value: compliance['late']!.toDouble(),
                          title: '延遲',
                          radius: 50,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        PieChartSectionData(
                          color: StatusColors.missed,
                          value: compliance['missed']!.toDouble(),
                          title: '未服',
                          radius: 50,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              '準時率: ${compliance['total']! > 0 ? (compliance['onTime']! / compliance['total']! * 100).toStringAsFixed(1) : 0}%',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemperatureChart(BuildContext context, List<EnvReading> envReadings) {
    final theme = Theme.of(context);
    
    if (envReadings.isEmpty) {
      return _buildEmptyChart(context, '溫度趨勢');
    }
    
    final temperatures = envReadings.map((e) => e.tempC).toList();
    final dataMin = temperatures.reduce((a, b) => a < b ? a : b);
    final dataMax = temperatures.reduce((a, b) => a > b ? a : b);
    
    // 使用與 trend_chart 相同的邏輯計算 Y 軸範圍
    final range = dataMax - dataMin;
    final buffer = range < 10 ? 5.0 : range * 0.2;
    
    // 向下取整到最近的 10 的倍數
    double minTemp = ((dataMin - buffer) / 10).floor() * 10.0;
    // 向上取整到最近的 10 的倍數
    double maxTemp = ((dataMax + buffer) / 10).ceil() * 10.0;
    
    // 確保最小範圍為 30
    if (maxTemp - minTemp < 30) {
      final center = (minTemp + maxTemp) / 2;
      minTemp = ((center - 15) / 10).floor() * 10.0;
      maxTemp = ((center + 15) / 10).ceil() * 10.0;
    }
    
    return LiquidGlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      gradientStart: LiquidGlassColors.accentPink.withOpacity(0.2),
      gradientEnd: LiquidGlassColors.accentPink.withOpacity(0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      ChartColors.temperature.withOpacity(0.3),
                      ChartColors.temperature.withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Icon(
                  Icons.thermostat,
                  color: ChartColors.temperature,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '溫度趨勢 (近5天)',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: (envReadings.length - 1).toDouble(),
                  minY: minTemp,
                  maxY: maxTemp,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 10,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: theme.colorScheme.outline.withOpacity(0.2),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= envReadings.length || index < 0) return const SizedBox.shrink();
                          final reading = envReadings[index];
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '${reading.timestamp.month}/${reading.timestamp.day}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 10,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 10,
                        reservedSize: 35,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 10,
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: envReadings.asMap().entries.map((e) {
                        return FlSpot(e.key.toDouble(), e.value.tempC);
                      }).toList(),
                      isCurved: true,
                      color: ChartColors.temperature,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHumidityChart(BuildContext context, List<EnvReading> envReadings) {
    final theme = Theme.of(context);
    
    if (envReadings.isEmpty) {
      return _buildEmptyChart(context, '濕度趨勢');
    }
    
    final humidities = envReadings.map((e) => e.humidity).toList();
    final dataMin = humidities.reduce((a, b) => a < b ? a : b);
    final dataMax = humidities.reduce((a, b) => a > b ? a : b);
    
    // 使用與 trend_chart 相同的邏輯計算 Y 軸範圍
    final range = dataMax - dataMin;
    final buffer = range < 10 ? 5.0 : range * 0.2;
    
    // 向下取整到最近的 10 的倍數
    double minHumidity = ((dataMin - buffer) / 10).floor() * 10.0;
    // 向上取整到最近的 10 的倍數
    double maxHumidity = ((dataMax + buffer) / 10).ceil() * 10.0;
    
    // 確保最小範圍為 30
    if (maxHumidity - minHumidity < 30) {
      final center = (minHumidity + maxHumidity) / 2;
      minHumidity = ((center - 15) / 10).floor() * 10.0;
      maxHumidity = ((center + 15) / 10).ceil() * 10.0;
    }
    
    return LiquidGlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      gradientStart: LiquidGlassColors.accentCyan.withOpacity(0.2),
      gradientEnd: LiquidGlassColors.accentCyan.withOpacity(0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      ChartColors.humidity.withOpacity(0.3),
                      ChartColors.humidity.withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Icon(
                  Icons.water_drop,
                  color: ChartColors.humidity,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '濕度趨勢 (近5天)',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: (envReadings.length - 1).toDouble(),
                  minY: minHumidity,
                  maxY: maxHumidity,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 10,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: theme.colorScheme.outline.withOpacity(0.2),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= envReadings.length || index < 0) return const SizedBox.shrink();
                          final reading = envReadings[index];
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '${reading.timestamp.month}/${reading.timestamp.day}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 10,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 10,
                        reservedSize: 35,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 10,
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: envReadings.asMap().entries.map((e) {
                        return FlSpot(e.key.toDouble(), e.value.humidity);
                      }).toList(),
                      isCurved: true,
                      color: ChartColors.humidity,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChart(BuildContext context, [String title = '暫無數據']) {
    final theme = Theme.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.show_chart,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context, Map<String, int> compliance) {
    final theme = Theme.of(context);
    
    return LiquidGlassCard(
      margin: const EdgeInsets.all(16),
      gradientStart: LiquidGlassColors.glassWhite.withOpacity(0.8),
      gradientEnd: LiquidGlassColors.glassWhite.withOpacity(0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      LiquidGlassColors.primaryBlue.withOpacity(0.3),
                      LiquidGlassColors.primaryBlue.withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Icon(
                  Icons.analytics,
                  color: LiquidGlassColors.primaryBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '統計摘要 (近5天)',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  context,
                  '總服藥次數',
                  '${compliance['total']}',
                  Icons.medication,
                  theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSummaryCard(
                  context,
                  '準時率',
                  '${compliance['total']! > 0 ? (compliance['onTime']! / compliance['total']! * 100).toStringAsFixed(1) : 0}%',
                  Icons.check_circle,
                  StatusColors.onTime,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    
    return LiquidGlassCard(
      padding: const EdgeInsets.all(16),
      gradientStart: color.withOpacity(0.2),
      gradientEnd: color.withOpacity(0.1),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  color.withOpacity(0.3),
                  color.withOpacity(0.1),
                  Colors.transparent,
                ],
              ),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}