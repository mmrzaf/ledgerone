import 'package:flutter/material.dart';
import '../../../app/di.dart';
import '../../../core/contracts/analytics_contract.dart';
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

      if (mounted) {
        setState(() => _loading = false);
      }
    } catch (e) {
      debugPrint('Error initializing services: $e');
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

  Future<void> _toggleTheme() async {
    await _themeService.toggleBrightness();

    if (mounted) {
      setState(() {});

      await widget.analytics.logEvent(
        'settings_theme_toggled',
        parameters: {'theme': _themeService.currentTheme.name},
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
                  _buildExportTile(theme, l10n),
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

  Widget _buildThemeTile(ThemeData theme, LocalizationService l10n) {
    final currentTheme = _themeService.currentTheme;
    final themeLabel = currentTheme.isDark
        ? l10n.get(L10nKeys.ledgerSettingsThemeDark)
        : l10n.get(L10nKeys.ledgerSettingsThemeLight);

    return ListTile(
      leading: Icon(currentTheme.isDark ? Icons.dark_mode : Icons.light_mode),
      title: Text(l10n.get(L10nKeys.ledgerSettingsTheme)),
      subtitle: Text(themeLabel),
      trailing: Switch(
        value: currentTheme.isDark,
        onChanged: (_) => _toggleTheme(),
      ),
      onTap: _toggleTheme,
    );
  }

  Widget _buildBackupTile(ThemeData theme, LocalizationService l10n) {
    return ListTile(
      leading: const Icon(Icons.backup),
      title: Text(l10n.get(L10nKeys.ledgerSettingsBackup)),
      subtitle: const Text('Export all data'),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        widget.analytics.logEvent('backup_export_clicked');
        _showComingSoon(l10n);
      },
    );
  }

  Widget _buildRestoreTile(ThemeData theme, LocalizationService l10n) {
    return ListTile(
      leading: const Icon(Icons.restore),
      title: Text(l10n.get(L10nKeys.ledgerSettingsRestore)),
      subtitle: const Text('Import from backup'),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () => _showComingSoon(l10n),
    );
  }

  Widget _buildExportTile(ThemeData theme, LocalizationService l10n) {
    return ListTile(
      leading: const Icon(Icons.file_download),
      title: Text(l10n.get(L10nKeys.ledgerSettingsExport)),
      subtitle: const Text('Export as CSV'),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () => _showComingSoon(l10n),
    );
  }

  Widget _buildVersionTile(ThemeData theme, LocalizationService l10n) {
    return ListTile(
      leading: const Icon(Icons.info_outline),
      title: Text(l10n.get(L10nKeys.ledgerSettingsVersion)),
      subtitle: const Text('0.9.3'),
    );
  }

  void _showComingSoon(LocalizationService l10n) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Coming soon'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
