import 'package:flutter/material.dart';
import '../../models/medication.dart';
import '../../models/intake_record.dart';
import '../../theme.dart';

class MedicationTile extends StatelessWidget {
  final Medication medication;
  final IntakeRecord? latestRecord;
  final bool hasWarning;
  final VoidCallback? onTap;

  const MedicationTile({
    super.key,
    required this.medication,
    this.latestRecord,
    this.hasWarning = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          medication.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${medication.dose} - ${medication.schedule}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusIndicator(context),
                  if (hasWarning)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: StatusColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        Icons.warning,
                        size: 16,
                        color: StatusColors.warning,
                      ),
                    ),
                ],
              ),
              if (medication.rfidTag != null) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.nfc,
                      size: 12,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        'RFID: ${medication.rfidTag}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontSize: 10,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ],
              if (medication.expiry != null) ...[
                const SizedBox(height: 1),
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 12,
                      color: _getExpiryColor(medication.daysUntilExpiry),
                    ),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        _getExpiryText(medication.daysUntilExpiry),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: _getExpiryColor(medication.daysUntilExpiry),
                          fontWeight: FontWeight.w500,
                          fontSize: 10,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(BuildContext context) {
    if (latestRecord == null) {
      return Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: Colors.grey,
          shape: BoxShape.circle,
        ),
      );
    }

    Color statusColor;
    switch (latestRecord!.status) {
      case IntakeStatus.onTime:
        statusColor = StatusColors.onTime;
        break;
      case IntakeStatus.late:
        statusColor = StatusColors.late;
        break;
      case IntakeStatus.missed:
        statusColor = StatusColors.missed;
        break;
    }

    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: statusColor,
        shape: BoxShape.circle,
      ),
    );
  }

  Color _getExpiryColor(int? daysUntilExpiry) {
    if (daysUntilExpiry == null) return Colors.grey;
    
    if (daysUntilExpiry <= 0) {
      return StatusColors.error;
    } else if (daysUntilExpiry <= 7) {
      return StatusColors.warning;
    } else {
      return StatusColors.success;
    }
  }

  String _getExpiryText(int? daysUntilExpiry) {
    if (daysUntilExpiry == null) return '無到期日';
    
    if (daysUntilExpiry <= 0) {
      return '已過期';
    } else if (daysUntilExpiry == 1) {
      return '明日到期';
    } else if (daysUntilExpiry <= 7) {
      return '${daysUntilExpiry}天後到期';
    } else {
      return '${daysUntilExpiry}天後到期';
    }
  }
}
