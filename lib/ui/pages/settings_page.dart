import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../providers/patient_providers.dart';
import '../../theme.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final selectedPatient = ref.watch(selectedPatientProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
      ),
      body: ListView(
        children: [
          // 目前病人
          _buildSectionHeader(context, '目前病人'),
          _buildPatientCard(context, selectedPatient),
          
          const SizedBox(height: 24),
          
          // 外觀設定
          _buildSectionHeader(context, '外觀設定'),
          _buildThemeSelector(context, ref, themeMode),
          
          const SizedBox(height: 24),
          
          // 量測設定
          _buildSectionHeader(context, '量測設定'),
          _buildMeasurementSettings(context),
          
          const SizedBox(height: 24),
          
          // 其他設定
          _buildSectionHeader(context, '其他'),
          _buildOtherSettings(context),
          
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildPatientCard(BuildContext context, selectedPatient) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary,
          child: Text(
            selectedPatient?.name.isNotEmpty == true 
                ? selectedPatient!.name[0] 
                : '?',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(selectedPatient?.name ?? '未選擇病人'),
        subtitle: Text('ID: ${selectedPatient?.id ?? 'N/A'}'),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          // TODO: 導航到病人選擇頁面
        },
      ),
    );
  }

  Widget _buildThemeSelector(BuildContext context, WidgetRef ref, ThemeMode themeMode) {
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.light_mode),
            title: const Text('亮色模式'),
            trailing: Radio<ThemeMode>(
              value: ThemeMode.light,
              groupValue: themeMode,
              onChanged: (value) {
                if (value != null) {
                  ref.read(themeModeProvider.notifier).setThemeMode(value);
                }
              },
            ),
            onTap: () {
              ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light);
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.dark_mode),
            title: const Text('暗色模式'),
            trailing: Radio<ThemeMode>(
              value: ThemeMode.dark,
              groupValue: themeMode,
              onChanged: (value) {
                if (value != null) {
                  ref.read(themeModeProvider.notifier).setThemeMode(value);
                }
              },
            ),
            onTap: () {
              ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.brightness_auto),
            title: const Text('跟隨系統'),
            trailing: Radio<ThemeMode>(
              value: ThemeMode.system,
              groupValue: themeMode,
              onChanged: (value) {
                if (value != null) {
                  ref.read(themeModeProvider.notifier).setThemeMode(value);
                }
              },
            ),
            onTap: () {
              ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.system);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementSettings(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.schedule),
            title: const Text('預設量測時間'),
            subtitle: const Text('12:00'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              _showTimePicker(context);
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('量測提醒'),
            subtitle: const Text('開啟'),
            trailing: Switch(
              value: true,
              onChanged: (value) {
                // TODO: 實作提醒開關
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtherSettings(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('匯出 DEMO 報表'),
            subtitle: const Text('生成假 CSV 檔案'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              _showExportDialog(context);
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('關於應用程式'),
            subtitle: const Text('版本 1.0.0'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              _showAboutDialog(context);
            },
          ),
        ],
      ),
    );
  }

  void _showTimePicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('選擇量測時間'),
        content: const Text('此功能僅影響顯示文案，實際資料仍由隨機器產生在 12:00±20 分鐘'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('關閉'),
          ),
        ],
      ),
    );
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('匯出報表'),
        content: const Text('此功能尚未實作，將在未來版本中提供 CSV 報表匯出功能。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('關閉'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: '醫療監控系統',
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2024 Demo Application',
      children: [
        const Text('這是一個醫療監控系統的示範應用程式，使用 Flutter 開發。'),
        const SizedBox(height: 16),
        const Text('功能特色：'),
        const Text('• 生命跡象監測'),
        const Text('• 用藥管理'),
        const Text('• 數據分析'),
        const Text('• 多病人支援'),
      ],
    );
  }
}
