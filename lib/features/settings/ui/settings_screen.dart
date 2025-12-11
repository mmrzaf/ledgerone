import 'package:flutter/material.dart';
import 'package:ledgerone/core/observability/app_logger.dart';

import '../../../app/di.dart';
import '../../../core/contracts/analytics_contract.dart';
import '../../../core/contracts/backup_contract.dart';
import '../../../core/contracts/i18n_contract.dart';
import '../../../core/contracts/navigation_contract.dart';
import '../../../core/contracts/theme_contract.dart';
import '../../../core/i18n/string_keys.dart';

class SettingsScreen extends StatefulWidget {
  final NavigationService navigation;
  final AnalyticsService analytics;

  const SettingsScreen({
    required this.navigation,
    required this.analytics,
    super.key,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late LocalizationService _localization;
  late ThemeService _themeService;
  late BackupService _backupService;

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    widget.analytics.logScreenView('settings');
    _initServices();
  }

  Future<void> _initServices() async {
    try {
      _localization = ServiceLocator().get<LocalizationService>();
      _themeService = ServiceLocator().get<ThemeService>();
      _backupService = ServiceLocator().get<BackupService>();

      if (mounted) {
        setState(() => _loading = false);
      }
    } catch (e) {
      AppLogger.info('Error initializing services: $e', tag: 'Error');
    }
  }

  Future<void> _changeLanguage(String languageCode) async {
    await _localization.setLocale(languageCode);

    if (mounted) {
      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_localization.get(L10nKeys.ledgerSettingsLanguage)),
          duration: const Duration(seconds: 1),
        ),
      );

      await widget.analytics.logEvent(
        'settings_language_changed',
        parameters: {'language': languageCode},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.get(L10nKeys.ledgerSettingsTitle)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => widget.navigation.goBack(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                _buildSection(theme, l10n, L10nKeys.ledgerSettingsGeneral, [
                  _buildLanguageTile(theme, l10n),
                  _buildThemeTile(theme, l10n),
                ]),
                const Divider(height: 32),
                _buildSection(theme, l10n, L10nKeys.ledgerSettingsData, [
                  _buildBackupTile(theme, l10n),
                  _buildRestoreTile(theme, l10n),
                ]),
                const Divider(height: 32),
                _buildSection(theme, l10n, 'Developer', [
                  _buildLogsTile(theme),
                ]),
                const Divider(height: 32),
                _buildSection(theme, l10n, L10nKeys.ledgerSettingsAbout, [
                  _buildVersionTile(theme, l10n),
                ]),
              ],
            ),
    );
  }

  Widget _buildSection(
    ThemeData theme,
    LocalizationService l10n,
    String titleKey,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            l10n.get(titleKey),
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildLanguageTile(ThemeData theme, LocalizationService l10n) {
    final currentLocale = _localization.currentLocale;

    return ListTile(
      leading: const Icon(Icons.language),
      title: Text(l10n.get(L10nKeys.ledgerSettingsLanguage)),
      subtitle: Text(currentLocale.displayName),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () => _showLanguagePicker(context, theme, l10n),
    );
  }

  void _showLanguagePicker(
    BuildContext context,
    ThemeData theme,
    LocalizationService l10n,
  ) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _localization.supportedLocales.map((locale) {
            final isSelected =
                locale.languageCode == _localization.currentLocale.languageCode;

            return ListTile(
              leading: isSelected
                  ? Icon(Icons.check, color: theme.colorScheme.primary)
                  : const SizedBox(width: 24),
              title: Text(
                locale.displayName,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? theme.colorScheme.primary : null,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _changeLanguage(locale.languageCode);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBackupTile(ThemeData theme, LocalizationService l10n) {
    return ListTile(
      leading: const Icon(Icons.backup),
      title: Text(l10n.get(L10nKeys.ledgerSettingsBackup)),
      subtitle: const Text('Export all data as JSON'),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () async {
        await widget.analytics.logEvent('backup_export_clicked');
        await _exportBackupAsJsonDialog(l10n);
      },
    );
  }

  Widget _buildRestoreTile(ThemeData theme, LocalizationService l10n) {
    return ListTile(
      leading: const Icon(Icons.restore),
      title: Text(l10n.get(L10nKeys.ledgerSettingsRestore)),
      subtitle: const Text('Restore from JSON backup'),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () async {
        await _restoreFromJsonDialog(l10n);
      },
    );
  }

  Widget _buildLogsTile(ThemeData theme) {
    return ListTile(
      leading: const Icon(Icons.bug_report),
      title: const Text('Application Logs'),
      subtitle: const Text('View debug and error logs'),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () => widget.navigation.goToRoute('logs'),
    );
  }

  Widget _buildVersionTile(ThemeData theme, LocalizationService l10n) {
    return ListTile(
      leading: const Icon(Icons.info_outline),
      title: Text(l10n.get(L10nKeys.ledgerSettingsVersion)),
      subtitle: const Text('0.9.10'),
    );
  }

  Future<void> _exportBackupAsJsonDialog(LocalizationService l10n) async {
    final theme = Theme.of(context);
    String? json;

    try {
      json = await _backupService.exportToJson();
    } catch (e) {
      AppLogger.error('Backup export failed: $e', tag: 'Backup');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.get(L10nKeys.error)),
          backgroundColor: theme.colorScheme.error,
        ),
      );
      return;
    }

    if (!mounted) return;

    final controller = TextEditingController(text: json);

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Backup JSON'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(
              controller.text,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.get(L10nKeys.ledgerCommonClose)),
          ),
        ],
      ),
    );

    controller.dispose();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Backup created. Copy and save as a .json file.'),
      ),
    );
  }

  Future<void> _restoreFromJsonDialog(LocalizationService l10n) async {
    final theme = Theme.of(context);
    final jsonController = TextEditingController();

    final confirmedJson = await showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore from backup'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Paste the JSON content of your LedgerOne backup file.\n\n'
                'Warning: this will overwrite your current data.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: jsonController,
                maxLines: 12,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Paste backup JSON here...',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: Text(l10n.get(L10nKeys.ledgerCommonCancel)),
          ),
          TextButton(
            onPressed: () {
              final text = jsonController.text.trim();
              if (text.isEmpty) {
                Navigator.of(ctx).pop(null);
              } else {
                Navigator.of(ctx).pop(text);
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            child: Text(l10n.get(L10nKeys.ledgerCommonConfirm)),
          ),
        ],
      ),
    );

    jsonController.dispose();

    if (!mounted || confirmedJson == null || confirmedJson.isEmpty) return;

    final sure = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Overwrite current data?'),
        content: const Text(
          'This will replace all current LedgerOne data with the backup '
          'you pasted. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.get(L10nKeys.ledgerCommonCancel)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            child: Text(l10n.get(L10nKeys.ledgerCommonConfirm)),
          ),
        ],
      ),
    );

    if (!mounted || sure != true) return;

    try {
      await _backupService.restoreFromJson(confirmedJson, clearExisting: true);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup restored successfully.')),
      );
    } catch (e) {
      AppLogger.error('Backup restore failed: $e', tag: 'Backup');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to restore backup: $e'),
          backgroundColor: theme.colorScheme.error,
        ),
      );
    }
  }

  Widget _buildThemeTile(ThemeData theme, LocalizationService l10n) {
    final currentTheme = _themeService.currentTheme;

    return ListTile(
      leading: const Icon(Icons.color_lens),
      title: Text(l10n.get(L10nKeys.ledgerSettingsTheme)),
      subtitle: Text(currentTheme.name),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: _showThemePicker,
    );
  }

  void _showThemePicker() {
    final themes = _themeService.availableThemes;
    final current = _themeService.currentTheme;

    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return ListView(
          shrinkWrap: true,
          children: themes.map((t) {
            final isSelected = t.name == current.name;
            return ListTile(
              title: Text(t.name),
              trailing: isSelected
                  ? Icon(Icons.check, color: theme.colorScheme.primary)
                  : null,
              onTap: () async {
                Navigator.pop(ctx);
                await _themeService.setTheme(t);
              },
            );
          }).toList(),
        );
      },
    );
  }
}
