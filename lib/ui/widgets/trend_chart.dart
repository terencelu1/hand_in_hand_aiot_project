import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/vital_sample.dart';
import '../../theme.dart';
import 'liquid_glass_card.dart';

class TrendChart extends StatefulWidget {
  final List<VitalSample> data;
  final ChartType type;
  final VoidCallback? onTypeChanged;

  const TrendChart({
    super.key,
    required this.data,
    required this.type,
    this.onTypeChanged,
  });

  @override
  State<TrendChart> createState() => _TrendChartState();
}

enum ChartType { heartRate, spo2 }

class _TrendChartState extends State<TrendChart> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return LiquidGlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  '近7天趨勢',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTypeButton(
                    context,
                    '心率',
                    ChartType.heartRate,
                    Icons.favorite,
                  ),
                  const SizedBox(width: 8),
                  _buildTypeButton(
                    context,
                    '血氧',
                    ChartType.spo2,
                    Icons.air,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: SizedBox(
              height: 200,
              child: widget.data.isEmpty
                  ? _buildEmptyState(context)
                  : LineChart(_buildChartData(context)),
            ),
          ),
          const SizedBox(height: 8),
          _buildChartSummary(context),
        ],
      ),
    );
  }

  Widget _buildTypeButton(
    BuildContext context,
    String label,
    ChartType type,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    final isSelected = widget.type == type;
    
    return Flexible(
      child: LiquidGlassButton(
        onPressed: () {
          if (widget.onTypeChanged != null && !isSelected) {
            widget.onTypeChanged!();
          }
        },
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        gradientStart: isSelected 
            ? LiquidGlassColors.primaryPurple
            : null,
        gradientEnd: isSelected 
            ? LiquidGlassColors.accentCyan
            : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected 
                  ? Colors.white
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isSelected 
                      ? Colors.white
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                  fontSize: 11,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
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
            Icons.show_chart,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 8),
          Text(
            '暫無數據',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  LineChartData _buildChartData(BuildContext context) {
    final theme = Theme.of(context);
    final spots = <FlSpot>[];
    
    for (int i = 0; i < widget.data.length; i++) {
      final sample = widget.data[i];
      final value = widget.type == ChartType.heartRate 
          ? sample.heartRate.toDouble()
          : sample.spo2.toDouble();
      spots.add(FlSpot(i.toDouble(), value));
    }

    // 動態計算 Y 軸範圍
    double minY, maxY;
    if (widget.data.isEmpty) {
      minY = widget.type == ChartType.heartRate ? 60 : 90;
      maxY = widget.type == ChartType.heartRate ? 100 : 100;
    } else {
      final values = widget.data.map((sample) => 
        widget.type == ChartType.heartRate 
            ? sample.heartRate.toDouble()
            : sample.spo2.toDouble()
      ).toList();
      
      final dataMin = values.reduce((a, b) => a < b ? a : b);
      final dataMax = values.reduce((a, b) => a > b ? a : b);
      
      // 計算合理的 Y 軸範圍，使用以 10 為單位的刻度
      final range = dataMax - dataMin;
      
      // 添加適當的上下緩衝空間（至少 5 個單位）
      final buffer = range < 10 ? 5.0 : range * 0.2;
      
      // 向下取整到最近的 10 的倍數
      minY = ((dataMin - buffer) / 10).floor() * 10.0;
      // 向上取整到最近的 10 的倍數
      maxY = ((dataMax + buffer) / 10).ceil() * 10.0;
      
      // 確保最小範圍為 30（至少顯示 3 個刻度間隔）
      if (maxY - minY < 30) {
        final center = (minY + maxY) / 2;
        minY = ((center - 15) / 10).floor() * 10.0;
        maxY = ((center + 15) / 10).ceil() * 10.0;
      }
    }

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 10, // 統一使用 10 為刻度間隔
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: theme.colorScheme.outline.withOpacity(0.2),
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index >= widget.data.length || index < 0) {
                return const SizedBox.shrink();
              }
              final sample = widget.data[index];
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
            interval: 10, // 統一使用 10 為刻度間隔
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
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      minX: 0,
      maxX: widget.data.isEmpty ? 0 : (widget.data.length - 1).toDouble(),
      minY: minY,
      maxY: maxY,
      baselineY: 0,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          gradient: LinearGradient(
            colors: [
              widget.type == ChartType.heartRate 
                  ? ChartColors.heartRate
                  : ChartColors.spo2,
              (widget.type == ChartType.heartRate 
                  ? ChartColors.heartRate
                  : ChartColors.spo2).withOpacity(0.3),
            ],
          ),
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: widget.type == ChartType.heartRate 
                    ? ChartColors.heartRate
                    : ChartColors.spo2,
                strokeWidth: 2,
                strokeColor: theme.colorScheme.surface,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                (widget.type == ChartType.heartRate 
                    ? ChartColors.heartRate
                    : ChartColors.spo2).withOpacity(0.1),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChartSummary(BuildContext context) {
    final theme = Theme.of(context);
    
    if (widget.data.isEmpty) return const SizedBox.shrink();
    
    final values = widget.data.map((sample) => 
        widget.type == ChartType.heartRate ? sample.heartRate : sample.spo2
    ).toList();
    
    final avg = values.reduce((a, b) => a + b) / values.length;
    
    String summary;
    if (widget.type == ChartType.heartRate) {
      if (avg >= 70 && avg <= 80) {
        summary = '本週心率穩定';
      } else if (avg < 70) {
        summary = '本週心率偏低';
      } else {
        summary = '本週心率偏高';
      }
    } else {
      if (avg >= 96 && avg <= 99) {
        summary = '本週血氧穩定於 ${avg.toStringAsFixed(1)}%';
      } else if (avg < 96) {
        summary = '本週血氧偏低';
      } else {
        summary = '本週血氧正常';
      }
    }
    
    return Text(
      summary,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontStyle: FontStyle.italic,
      ),
    );
  }
}
