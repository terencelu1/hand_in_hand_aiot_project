import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../ui/pages/dashboard_page.dart';
import '../ui/pages/records_page.dart';
import '../ui/pages/analytics_page.dart';
import '../ui/pages/notifications_page.dart';
import '../ui/pages/patients_page.dart';
import '../ui/pages/settings_page.dart';
import '../ui/widgets/liquid_glass_background.dart';
import '../theme.dart';
import 'dart:ui';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        return MainNavigationShell(child: child);
      },
      routes: [
        GoRoute(
          path: '/',
          name: 'dashboard',
          builder: (context, state) => const DashboardPage(),
        ),
        GoRoute(
          path: '/records',
          name: 'records',
          builder: (context, state) => const RecordsPage(),
        ),
        GoRoute(
          path: '/analytics',
          name: 'analytics',
          builder: (context, state) => const AnalyticsPage(),
        ),
        GoRoute(
          path: '/notifications',
          name: 'notifications',
          builder: (context, state) => const NotificationsPage(),
        ),
        GoRoute(
          path: '/patients',
          name: 'patients',
          builder: (context, state) => const PatientsPage(),
        ),
        GoRoute(
          path: '/settings',
          name: 'settings',
          builder: (context, state) => const SettingsPage(),
        ),
      ],
    ),
  ],
);

class MainNavigationShell extends StatelessWidget {
  final Widget child;

  const MainNavigationShell({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return LiquidGlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: child,
        bottomNavigationBar: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5), // 減少模糊強度
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: theme.brightness == Brightness.dark
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
                  boxShadow: [
                    BoxShadow(
                      color: LiquidGlassColors.glassShadow,
                      blurRadius: 12, // 減少模糊半徑
                      offset: const Offset(0, 4), // 減少偏移
                    ),
                  ],
                ),
                child: Container(
                  height: 80,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNavItem(context, 0, Icons.dashboard, '首頁'),
                      _buildNavItem(context, 1, Icons.assignment, '紀錄'),
                      _buildNavItem(context, 2, Icons.analytics, '分析'),
                      _buildNavItem(context, 3, Icons.more_horiz, '更多'),
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

  int _getCurrentIndex(BuildContext context) {
    try {
      final location = GoRouterState.of(context).uri.path;
      switch (location) {
        case '/':
          return 0;
        case '/records':
          return 1;
        case '/analytics':
          return 2;
        case '/notifications':
        case '/patients':
        case '/settings':
          return 3; // 更多選單
        default:
          return 0;
      }
    } catch (e) {
      return 0; // 如果出錯，預設回到首頁
    }
  }

  Widget _buildNavItem(BuildContext context, int index, IconData icon, String label) {
    final theme = Theme.of(context);
    final currentIndex = _getCurrentIndex(context);
    final isSelected = currentIndex == index;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => _onTap(context, index),
        child: Container(
          height: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? (theme.brightness == Brightness.dark
                        ? LiquidGlassColors.accentCyan
                        : LiquidGlassColors.primaryPurple)
                    : theme.colorScheme.onSurfaceVariant,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isSelected
                      ? (theme.brightness == Brightness.dark
                          ? LiquidGlassColors.accentCyan
                          : LiquidGlassColors.primaryPurple)
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onTap(BuildContext context, int index) {
    try {
      switch (index) {
        case 0:
          context.go('/');
          break;
        case 1:
          context.go('/records');
          break;
        case 2:
          context.go('/analytics');
          break;
        case 3:
          _showMoreMenu(context);
          break;
      }
    } catch (e) {
      // 如果導航出錯，至少嘗試回到首頁
      context.go('/');
    }
  }

  void _showMoreMenu(BuildContext context) {
    try {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: LiquidGlassColors.glassShadow,
                blurRadius: 12, // 減少模糊半徑
                offset: const Offset(0, 4), // 減少偏移
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5), // 減少模糊強度
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
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildMenuTile(
                        context,
                        Icons.notifications,
                        '通知',
                        () {
                          Navigator.pop(context);
                          context.go('/notifications');
                        },
                      ),
                      _buildMenuTile(
                        context,
                        Icons.people,
                        '病人管理',
                        () {
                          Navigator.pop(context);
                          context.go('/patients');
                        },
                      ),
                      _buildMenuTile(
                        context,
                        Icons.settings,
                        '設定',
                        () {
                          Navigator.pop(context);
                          context.go('/settings');
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      // 如果彈出選單失敗，直接導航到設定頁面
      context.go('/settings');
    }
  }

  Widget _buildMenuTile(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.2),
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Colors.transparent,
            ],
          ),
        ),
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
