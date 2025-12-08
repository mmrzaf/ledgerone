import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../core/contracts/analytics_contract.dart';
import '../../../core/contracts/i18n_contract.dart';
import '../../../core/contracts/navigation_contract.dart';
import '../../../core/i18n/string_keys.dart';
import '../data/repositories_interfaces.dart';
import '../domain/models.dart';

class AssetsScreen extends StatefulWidget {
  final NavigationService navigation;
  final AssetRepository assetRepo;
  final AnalyticsService analytics;

  const AssetsScreen({
    required this.navigation,
    required this.assetRepo,
    required this.analytics,
    super.key,
  });

  @override
  State<AssetsScreen> createState() => _AssetsScreenState();
}

class _AssetsScreenState extends State<AssetsScreen> {
  bool _loading = true;
  bool _saving = false;
  List<Asset> _assets = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    widget.analytics.logScreenView('assets');
    _loadAssets();
  }

  Future<void> _loadAssets() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final assets = await widget.assetRepo.getAll();
      setState(() {
        _assets = assets;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _showEditor({Asset? asset}) async {
    final l10n = context.l10n;

    final nameController = TextEditingController(text: asset?.name ?? '');
    final symbolController = TextEditingController(text: asset?.symbol ?? '');
    AssetType type = asset?.type ?? AssetType.crypto;
    final decimalsController = TextEditingController(
      text: (asset?.decimals ?? 8).toString(),
    );
    final priceConfigController = TextEditingController(
      text: asset?.priceSourceConfig ?? '',
    );

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                asset == null
                    ? l10n.get(L10nKeys.ledgerCommonAdd)
                    : l10n.get(L10nKeys.ledgerCommonEdit),
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: symbolController,
                decoration: const InputDecoration(labelText: 'Symbol'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<AssetType>(
                initialValue: type,
                decoration: const InputDecoration(labelText: 'Type'),
                items: AssetType.values
                    .map((t) => DropdownMenuItem(value: t, child: Text(t.name)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      type = value;
                    });
                  }
                },
              ),
              TextField(
                controller: decimalsController,
                decoration: const InputDecoration(labelText: 'Decimals'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: priceConfigController,
                decoration: const InputDecoration(
                  labelText: 'Price source config (JSON, optional)',
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(l10n.get(L10nKeys.ledgerCommonCancel)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(l10n.get(L10nKeys.ledgerCommonSave)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (result != true) return;

    final name = nameController.text.trim();
    final symbol = symbolController.text.trim();
    final decimals = int.tryParse(decimalsController.text.trim()) ?? 8;
    final priceConfig = priceConfigController.text.trim().isEmpty
        ? null
        : priceConfigController.text.trim();

    if (name.isEmpty || symbol.isEmpty) return;

    setState(() => _saving = true);
    try {
      final now = DateTime.now();
      final newAsset = Asset(
        id: asset?.id ?? const Uuid().v4(),
        symbol: symbol,
        name: name,
        type: type,
        decimals: decimals,
        priceSourceConfig: priceConfig,
        createdAt: now,
        updatedAt: now,
      );

      if (asset == null) {
        await widget.assetRepo.insert(newAsset);
      } else {
        await widget.assetRepo.update(newAsset);
      }

      await _loadAssets();
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _deleteAsset(Asset asset) async {
    await widget.assetRepo.delete(asset.id);
    await _loadAssets();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: l10n.get(L10nKeys.ledgerCommonClose),
          onPressed: () => widget.navigation.goBack(),
        ),
        title: Text(l10n.get(L10nKeys.ledgerCommonAssets)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : _assets.isEmpty
          ? Center(child: Text(l10n.get(L10nKeys.ledgerCommonNoData)))
          : ListView.separated(
              itemCount: _assets.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (ctx, index) {
                final asset = _assets[index];
                return ListTile(
                  title: Text('${asset.symbol} • ${asset.name}'),
                  subtitle: Text(asset.type.name),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showEditor(asset: asset);
                      } else if (value == 'delete') {
                        _deleteAsset(asset);
                      }
                    },
                    itemBuilder: (ctx) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Text(l10n.get(L10nKeys.ledgerCommonEdit)),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          l10n.get(L10nKeys.ledgerCommonDelete),
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ),
                    ],
                  ),
                  onTap: () => _showEditor(asset: asset),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saving ? null : () => _showEditor(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
