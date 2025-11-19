import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/vital_sample.dart';
import '../../theme.dart';
import 'liquid_glass_card.dart';

class VitalsCard extends StatelessWidget {
  final VitalSample? vitalSample;
  final VoidCallback? onRefresh;
  final bool isLoading;

  const VitalsCard({
    super.key,
    this.vitalSample,
    this.onRefresh,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return LiquidGlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '今日生命跡象',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              if (onRefresh != null)
                LiquidGlassButton(
                  width: 40,
                  height: 40,
                  padding: EdgeInsets.zero,
                  onPressed: isLoading ? null : onRefresh,
                  child: isLoading 
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          Icons.refresh,
                          color: theme.colorScheme.onSurface,
                          size: 20,
                        ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (vitalSample != null) ...[
            _buildVitalRow(
              context,
              '心率',
              '${vitalSample!.heartRate} bpm',
              Icons.favorite,
              _getHeartRateColor(vitalSample!.heartRate),
            ),
            const SizedBox(height: 12),
            _buildVitalRow(
              context,
              '血氧',
              '${vitalSample!.spo2}%',
              Icons.air,
              _getSpo2Color(vitalSample!.spo2),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('HH:mm').format(vitalSample!.timestamp),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                if (vitalSample!.quality < 0.6)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          StatusColors.warning.withOpacity(0.2),
                          StatusColors.warning.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: StatusColors.warning.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      '訊號品質偏低',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: StatusColors.warning,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ] else ...[
            _buildPlaceholder(context),
          ],
        ],
      ),
    );
  }

  Widget _buildVitalRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        Icon(
          icon,
          color: color,
          size: 24,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        Icon(
          Icons.schedule,
          size: 48,
          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
        ),
        const SizedBox(height: 8),
        Text(
          '預計於 12:00 ±20 分量測',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '請稍後再查看最新數據',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Color _getHeartRateColor(int heartRate) {
    if (heartRate < 60 || heartRate > 100) {
      return StatusColors.warning;
    }
    return StatusColors.success;
  }

  Color _getSpo2Color(int spo2) {
    if (spo2 < 95) {
      return StatusColors.warning;
    }
    return StatusColors.success;
  }
}
