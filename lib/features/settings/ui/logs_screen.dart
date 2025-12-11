import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/contracts/logging_contract.dart';
import '../../../core/contracts/navigation_contract.dart';

class LogsScreen extends StatefulWidget {
  final NavigationService navigation;
  final LoggingService loggingService;

  const LogsScreen({
    required this.navigation,
    required this.loggingService,
    super.key,
  });

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  LogLevel _filterLevel = LogLevel.debug;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Application Logs'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => widget.navigation.goBack(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copy all logs',
            onPressed: _copyAllLogs,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear logs',
            onPressed: _confirmClearLogs,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(theme),
          const Divider(height: 1),
          Expanded(child: _buildLogsList(theme)),
        ],
      ),
    );
  }

  Widget _buildFilters(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(
              labelText: 'Search logs',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: LogLevel.values.map((level) {
                final isSelected = _filterLevel == level;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(level.name.toUpperCase()),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _filterLevel = level),
                    avatar: isSelected
                        ? null
                        : Icon(
                            _iconForLevel(level),
                            size: 16,
                            color: _colorForLevel(level),
                          ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogsList(ThemeData theme) {
    return StreamBuilder<LogEntry>(
      stream: widget.loggingService.logStream,
      builder: (context, snapshot) {
        final logs =
            widget.loggingService.logs
                .where((log) => log.level.index >= _filterLevel.index)
                .where((log) {
                  if (_searchQuery.isEmpty) return true;
                  final query = _searchQuery.toLowerCase();
                  return log.message.toLowerCase().contains(query) ||
                      (log.tag?.toLowerCase().contains(query) ?? false);
                })
                .toList()
              ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

        if (logs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.assignment_outlined,
                  size: 64,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'No logs to display',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: logs.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) => _buildLogEntry(logs[index], theme),
        );
      },
    );
  }

  Widget _buildLogEntry(LogEntry log, ThemeData theme) {
    final color = _colorForLevel(log.level);

    return Card(
      elevation: 0,
      child: InkWell(
        onTap: () => _showLogDetail(log),
        onLongPress: () => _copyLog(log),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_iconForLevel(log.level), size: 16, color: color),
                  const SizedBox(width: 8),
                  Text(
                    log.level.name.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (log.tag != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(log.tag!, style: theme.textTheme.labelSmall),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    _formatTime(log.timestamp),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                log.message,
                style: theme.textTheme.bodyMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              if (log.error != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Error: ${log.error}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showLogDetail(LogEntry log) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final theme = Theme.of(context);
        final color = _colorForLevel(log.level);

        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.outline.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(_iconForLevel(log.level), color: color),
                      const SizedBox(width: 12),
                      Text(
                        log.level.name.toUpperCase(),
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: () {
                          _copyLog(log);
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow(
                            theme,
                            'Time',
                            log.timestamp.toString(),
                          ),
                          if (log.tag != null)
                            _buildDetailRow(theme, 'Tag', log.tag!),
                          _buildDetailRow(theme, 'Message', log.message),
                          if (log.error != null)
                            _buildDetailRow(
                              theme,
                              'Error',
                              log.error.toString(),
                            ),
                          if (log.stackTrace != null)
                            _buildDetailRow(
                              theme,
                              'Stack Trace',
                              log.stackTrace.toString(),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _copyLog(LogEntry log) async {
    await Clipboard.setData(ClipboardData(text: log.toString()));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Log copied to clipboard'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _copyAllLogs() async {
    final logs = widget.loggingService.logs
        .map((log) => log.toString())
        .join('\n');
    await Clipboard.setData(ClipboardData(text: logs));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All logs copied to clipboard'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _confirmClearLogs() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Logs'),
        content: const Text(
          'Are you sure you want to clear all logs? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await widget.loggingService.clear();
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Logs cleared')));
      }
    }
  }

  Color _colorForLevel(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return Colors.grey;
      case LogLevel.info:
        return Colors.blue;
      case LogLevel.warning:
        return Colors.orange;
      case LogLevel.error:
        return Colors.red;
    }
  }

  IconData _iconForLevel(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return Icons.bug_report;
      case LogLevel.info:
        return Icons.info_outline;
      case LogLevel.warning:
        return Icons.warning_amber;
      case LogLevel.error:
        return Icons.error_outline;
    }
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}:'
        '${dt.second.toString().padLeft(2, '0')}';
  }
}
