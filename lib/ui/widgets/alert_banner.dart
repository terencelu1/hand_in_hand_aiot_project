import 'package:flutter/material.dart';
import '../../theme.dart';
import 'liquid_glass_card.dart';

class AlertBanner extends StatelessWidget {
  final String title;
  final String message;
  final String type;
  final VoidCallback? onDismiss;
  final VoidCallback? onAction;
  final String? actionText;

  const AlertBanner({
    super.key,
    required this.title,
    required this.message,
    required this.type,
    this.onDismiss,
    this.onAction,
    this.actionText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = _getColorsForType(type);
    
    return LiquidGlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      gradientStart: colors.backgroundColor,
      gradientEnd: colors.backgroundColor.withOpacity(0.5),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  colors.iconColor.withOpacity(0.2),
                  colors.iconColor.withOpacity(0.1),
                  Colors.transparent,
                ],
              ),
            ),
            child: Icon(
              _getIconForType(type),
              color: colors.iconColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.black, // 改成黑色
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.black.withOpacity(0.8), // 改成黑色
                  ),
                ),
              ],
            ),
          ),
          if (onDismiss != null)
            LiquidGlassButton(
              width: 32,
              height: 32,
              padding: EdgeInsets.zero,
              onPressed: onDismiss,
              child: Icon(
                Icons.close,
                color: colors.iconColor.withOpacity(0.7),
                size: 16,
              ),
            ),
          if (onAction != null && actionText != null) ...[
            const SizedBox(width: 8),
            LiquidGlassButton(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              onPressed: onAction,
              gradientStart: colors.iconColor.withOpacity(0.2),
              gradientEnd: colors.iconColor.withOpacity(0.1),
              child: Text(
                actionText!,
                style: TextStyle(
                  color: colors.iconColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'warning':
        return Icons.warning;
      case 'error':
        return Icons.error;
      case 'info':
        return Icons.info;
      case 'success':
        return Icons.check_circle;
      default:
        return Icons.info;
    }
  }

  _AlertColors _getColorsForType(String type) {
    switch (type.toLowerCase()) {
      case 'warning':
        return _AlertColors(
          backgroundColor: StatusColors.warning.withOpacity(0.1),
          borderColor: StatusColors.warning.withOpacity(0.3),
          iconColor: StatusColors.warning,
          textColor: StatusColors.warning,
        );
      case 'error':
        return _AlertColors(
          backgroundColor: StatusColors.error.withOpacity(0.1),
          borderColor: StatusColors.error.withOpacity(0.3),
          iconColor: StatusColors.error,
          textColor: StatusColors.error,
        );
      case 'info':
        return _AlertColors(
          backgroundColor: StatusColors.info.withOpacity(0.1),
          borderColor: StatusColors.info.withOpacity(0.3),
          iconColor: StatusColors.info,
          textColor: StatusColors.info,
        );
      case 'success':
        return _AlertColors(
          backgroundColor: StatusColors.success.withOpacity(0.1),
          borderColor: StatusColors.success.withOpacity(0.3),
          iconColor: StatusColors.success,
          textColor: StatusColors.success,
        );
      default:
        return _AlertColors(
          backgroundColor: Colors.grey.withOpacity(0.1),
          borderColor: Colors.grey.withOpacity(0.3),
          iconColor: Colors.grey,
          textColor: Colors.grey,
        );
    }
  }
}

class _AlertColors {
  final Color backgroundColor;
  final Color borderColor;
  final Color iconColor;
  final Color textColor;

  _AlertColors({
    required this.backgroundColor,
    required this.borderColor,
    required this.iconColor,
    required this.textColor,
  });
}
