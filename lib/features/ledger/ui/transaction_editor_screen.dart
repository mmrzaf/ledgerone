import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/contracts/analytics_contract.dart';
import '../../../core/contracts/i18n_contract.dart';
import '../../../core/contracts/navigation_contract.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/i18n/string_keys.dart';
import '../data/repositories_interfaces.dart';
import '../domain/models.dart';
import '../domain/services.dart';

class TransactionEditorScreen extends StatefulWidget {
  final NavigationService navigation;
  final TransactionService transactionService;
  final AssetRepository assetRepo;
  final AccountRepository accountRepo;
  final CategoryRepository categoryRepo;
  final AnalyticsService analytics;
  final String? transactionId;

  const TransactionEditorScreen({
    required this.navigation,
    required this.transactionService,
    required this.assetRepo,
    required this.accountRepo,
    required this.categoryRepo,
    required this.analytics,
    this.transactionId,
    super.key,
  });

  @override
  State<TransactionEditorScreen> createState() =>
      _TransactionEditorScreenState();
}

class _TransactionEditorScreenState extends State<TransactionEditorScreen> {
  final _formKey = GlobalKey<FormState>();

  TransactionType _type = TransactionType.income;
  DateTime _timestamp = DateTime.now();
  final _descriptionController = TextEditingController();

  Account? _selectedAccount;
  Account? _toAccount;
  Asset? _selectedAsset;
  Asset? _fromAsset;
  Asset? _toAsset;
  Asset? _feeAsset;
  Category? _selectedCategory;

  final _amountController = TextEditingController();
  final _toAmountController = TextEditingController();
  final _feeAmountController = TextEditingController();

  List<Asset> _assets = [];
  List<Account> _accounts = [];
  List<Category> _categories = [];

  bool _loading = true;
  bool _saving = false;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.transactionId != null;

    widget.analytics.logScreenView(
      _isEditMode ? 'transaction_editor_edit' : 'transaction_editor',
    );

    _loadData();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _toAmountController.dispose();
    _feeAmountController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final assets = await widget.assetRepo.getAll();
      final accounts = await widget.accountRepo.getAll();
      final categories = await widget.categoryRepo.getAll();

      if (_isEditMode && widget.transactionId != null) {
        final tx = await widget.transactionService.getTransaction(
          widget.transactionId!,
        );
        final legs = await widget.transactionService.getLegsForTransaction(
          widget.transactionId!,
        );

        if (tx != null && legs.isNotEmpty) {
          _prefillFromTransaction(tx, legs, accounts, assets, categories);
        }
      }

      if (!mounted) return;

      setState(() {
        _assets = assets;
        _accounts = accounts;
        _categories = categories;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  void _prefillFromTransaction(
    Transaction tx,
    List<TransactionLeg> legs,
    List<Account> accounts,
    List<Asset> assets,
    List<Category> categories,
  ) {
    _type = tx.type;
    _timestamp = tx.timestamp;
    _descriptionController.text = tx.description;

    switch (tx.type) {
      case TransactionType.income:
      case TransactionType.expense:
        final mainLeg = legs.firstWhere((l) => l.role == LegRole.main);
        _selectedAccount = accounts.firstWhere(
          (a) => a.id == mainLeg.accountId,
        );
        _selectedAsset = assets.firstWhere((a) => a.id == mainLeg.assetId);
        _amountController.text = mainLeg.amount.abs().toString();

        if (mainLeg.categoryId != null) {
          _selectedCategory = categories
              .where((c) => c.id == mainLeg.categoryId)
              .firstOrNull;
        }
        break;

      case TransactionType.transfer:
        final fromLeg = legs.firstWhere((l) => l.amount < 0);
        final toLeg = legs.firstWhere((l) => l.amount > 0);

        _selectedAccount = accounts.firstWhere(
          (a) => a.id == fromLeg.accountId,
        );
        _toAccount = accounts.firstWhere((a) => a.id == toLeg.accountId);
        _selectedAsset = assets.firstWhere((a) => a.id == fromLeg.assetId);
        _amountController.text = fromLeg.amount.abs().toString();
        break;

      case TransactionType.trade:
        final fromLeg = legs.firstWhere(
          (l) => l.role == LegRole.main && l.amount < 0,
        );
        final toLeg = legs.firstWhere(
          (l) => l.role == LegRole.main && l.amount > 0,
        );
        final feeLeg = legs.where((l) => l.role == LegRole.fee).firstOrNull;

        _selectedAccount = accounts.firstWhere(
          (a) => a.id == fromLeg.accountId,
        );
        _fromAsset = assets.firstWhere((a) => a.id == fromLeg.assetId);
        _toAsset = assets.firstWhere((a) => a.id == toLeg.assetId);
        _amountController.text = fromLeg.amount.abs().toString();
        _toAmountController.text = toLeg.amount.toString();

        if (feeLeg != null) {
          _feeAsset = assets.where((a) => a.id == feeLeg.assetId).firstOrNull;
          _feeAmountController.text = feeLeg.amount.abs().toString();
        }
        break;

      case TransactionType.adjustment:
        final mainLeg = legs.firstWhere((l) => l.role == LegRole.main);
        _selectedAccount = accounts.firstWhere(
          (a) => a.id == mainLeg.accountId,
        );
        _selectedAsset = assets.firstWhere((a) => a.id == mainLeg.assetId);
        _amountController.text = mainLeg.amount.toString();
        break;
    }
  }

  void _onTypeChanged(TransactionType newType) {
    if (_type == newType) return;

    setState(() {
      _type = newType;

      // Clear type-specific fields
      switch (newType) {
        case TransactionType.income:
        case TransactionType.expense:
        case TransactionType.adjustment:
          _toAccount = null;
          _fromAsset = null;
          _toAsset = null;
          _feeAsset = null;
          _toAmountController.clear();
          _feeAmountController.clear();
          break;

        case TransactionType.transfer:
          _fromAsset = null;
          _toAsset = null;
          _feeAsset = null;
          _toAmountController.clear();
          _feeAmountController.clear();
          _selectedCategory = null;
          break;

        case TransactionType.trade:
          _toAccount = null;
          _selectedAsset = null;
          _selectedCategory = null;
          break;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final l10n = context.l10n;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;

    try {
      final description = _descriptionController.text.trim();

      if (_isEditMode && widget.transactionId != null) {
        final params = _buildTransactionParams(description);

        await widget.transactionService.updateTransaction(
          transactionId: widget.transactionId!,
          type: _type,
          params: params,
        );

        if (!mounted) return;

        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(l10n.get(L10nKeys.ledgerTxEditorUpdated)),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        await widget.analytics.logEvent(
          'transaction_updated',
          parameters: {'type': _type.name},
        );

        widget.navigation.goBack();
      } else {
        await _createTransaction(description);

        if (!mounted) return;

        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(l10n.get(L10nKeys.ledgerTxEditorCreated)),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        await widget.analytics.logEvent(
          'transaction_created',
          parameters: {'type': _type.name},
        );

        widget.navigation.goBack();
      }
    } on AppError catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);

      await widget.analytics.logEvent(
        'transaction_failed',
        parameters: {
          'type': _type.name,
          'error_category': e.category.name,
          'is_edit': _isEditMode,
        },
      );

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);

      await widget.analytics.logEvent(
        'transaction_failed',
        parameters: {
          'type': _type.name,
          'error': 'unexpected',
          'is_edit': _isEditMode,
        },
      );

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _createTransaction(String description) async {
    switch (_type) {
      case TransactionType.income:
        await widget.transactionService.createIncome(
          accountId: _selectedAccount!.id,
          assetId: _selectedAsset!.id,
          amount: _parseAmount(_amountController.text),
          categoryId: _selectedCategory?.id,
          description: description,
          timestamp: _timestamp,
        );
        break;

      case TransactionType.expense:
        await widget.transactionService.createExpense(
          accountId: _selectedAccount!.id,
          assetId: _selectedAsset!.id,
          amount: _parseAmount(_amountController.text),
          categoryId: _selectedCategory!.id,
          description: description,
          timestamp: _timestamp,
        );
        break;

      case TransactionType.transfer:
        await widget.transactionService.createTransfer(
          fromAccountId: _selectedAccount!.id,
          toAccountId: _toAccount!.id,
          assetId: _selectedAsset!.id,
          amount: _parseAmount(_amountController.text),
          description: description,
          timestamp: _timestamp,
        );
        break;

      case TransactionType.trade:
        await widget.transactionService.createTrade(
          accountId: _selectedAccount!.id,
          fromAssetId: _fromAsset!.id,
          fromAmount: _parseAmount(_amountController.text),
          toAssetId: _toAsset!.id,
          toAmount: _parseAmount(_toAmountController.text),
          feeAssetId: _feeAsset?.id,
          feeAmount: _feeAmountController.text.isEmpty
              ? null
              : _parseAmount(_feeAmountController.text),
          description: description,
          timestamp: _timestamp,
        );
        break;

      case TransactionType.adjustment:
        await widget.transactionService.createAdjustment(
          accountId: _selectedAccount!.id,
          assetId: _selectedAsset!.id,
          amount: _parseAmount(_amountController.text),
          description: description,
          timestamp: _timestamp,
        );
        break;
    }
  }

  Map<String, dynamic> _buildTransactionParams(String description) {
    final params = <String, dynamic>{
      'description': description,
      'timestamp': _timestamp,
    };

    switch (_type) {
      case TransactionType.income:
      case TransactionType.expense:
        params['accountId'] = _selectedAccount!.id;
        params['assetId'] = _selectedAsset!.id;
        params['amount'] = _parseAmount(_amountController.text);
        params['categoryId'] = _selectedCategory?.id;
        break;

      case TransactionType.transfer:
        params['fromAccountId'] = _selectedAccount!.id;
        params['toAccountId'] = _toAccount!.id;
        params['assetId'] = _selectedAsset!.id;
        params['amount'] = _parseAmount(_amountController.text);
        break;

      case TransactionType.trade:
        params['accountId'] = _selectedAccount!.id;
        params['fromAssetId'] = _fromAsset!.id;
        params['fromAmount'] = _parseAmount(_amountController.text);
        params['toAssetId'] = _toAsset!.id;
        params['toAmount'] = _parseAmount(_toAmountController.text);
        params['feeAssetId'] = _feeAsset?.id;
        params['feeAmount'] = _feeAmountController.text.isEmpty
            ? null
            : _parseAmount(_feeAmountController.text);
        break;

      case TransactionType.adjustment:
        params['accountId'] = _selectedAccount!.id;
        params['assetId'] = _selectedAsset!.id;
        params['amount'] = _parseAmount(_amountController.text);
        break;
    }

    return params;
  }

  double _parseAmount(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw const AppError(
        category: ErrorCategory.badRequest,
        message: 'Amount cannot be empty',
      );
    }

    final parsed = double.tryParse(trimmed);
    if (parsed == null ||
        (_type != TransactionType.adjustment && parsed == 0.0)) {
      throw const AppError(
        category: ErrorCategory.badRequest,
        message: 'Invalid amount',
      );
    }

    return parsed;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: l10n.get(L10nKeys.ledgerCommonClose),
          onPressed: () => widget.navigation.goBack(),
        ),
        title: Text(
          _isEditMode
              ? l10n.get(L10nKeys.ledgerTxEditorTitleEdit)
              : l10n.get(L10nKeys.ledgerTxEditorTitle),
        ),
        actions: [
          if (_saving)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _save,
              tooltip: l10n.get(L10nKeys.ledgerCommonSave),
            ),
        ],
      ),
      body: _loading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    l10n.get(L10nKeys.ledgerCommonLoadingData),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildTypeSelector(theme, l10n),
                  const SizedBox(height: 24),
                  _buildDateTimePicker(theme, l10n),
                  const SizedBox(height: 16),
                  _buildDescriptionField(l10n),
                  const SizedBox(height: 24),
                  ..._buildTypeSpecificFields(theme, l10n),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: Icon(_isEditMode ? Icons.save : Icons.add),
                      label: Text(
                        _isEditMode
                            ? l10n.get(L10nKeys.ledgerTxEditorUpdate)
                            : l10n.get(L10nKeys.ledgerTxEditorCreate),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  Widget _buildTypeSelector(ThemeData theme, LocalizationService l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.get(L10nKeys.ledgerTxEditorType),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: TransactionType.values.map((type) {
            final isSelected = type == _type;
            return ChoiceChip(
              label: Text(l10n.get('ledger.tx_type.${type.name}')),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) _onTypeChanged(type);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDateTimePicker(ThemeData theme, LocalizationService l10n) {
    return Card(
      elevation: 0,
      child: ListTile(
        leading: Icon(Icons.calendar_today, color: theme.colorScheme.primary),
        title: Text(l10n.get(L10nKeys.ledgerTxEditorDateTime)),
        subtitle: Text(_formatDateTime(_timestamp)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: _timestamp,
            firstDate: DateTime(2000),
            lastDate: DateTime.now(),
          );

          if (date != null && mounted) {
            final time = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.fromDateTime(_timestamp),
            );

            if (time != null) {
              setState(() {
                _timestamp = DateTime(
                  date.year,
                  date.month,
                  date.day,
                  time.hour,
                  time.minute,
                );
              });
            }
          }
        },
      ),
    );
  }

  Widget _buildDescriptionField(LocalizationService l10n) {
    return TextFormField(
      controller: _descriptionController,
      decoration: InputDecoration(
        labelText: l10n.get(L10nKeys.ledgerTxEditorDescription),
        hintText: l10n.get(L10nKeys.ledgerTxEditorDescriptionHint),
        prefixIcon: const Icon(Icons.description),
      ),
      maxLines: 2,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return l10n.get(L10nKeys.ledgerTxEditorDescriptionRequired);
        }
        return null;
      },
    );
  }

  List<Widget> _buildTypeSpecificFields(
    ThemeData theme,
    LocalizationService l10n,
  ) {
    switch (_type) {
      case TransactionType.income:
      case TransactionType.expense:
        return [
          _buildAccountDropdown(l10n),
          const SizedBox(height: 16),
          _buildAssetDropdown(l10n),
          const SizedBox(height: 16),
          _buildAmountField(l10n, L10nKeys.ledgerTxEditorAmount),
          const SizedBox(height: 16),
          _buildCategoryDropdown(
            l10n,
            _type == TransactionType.income ? 'income' : 'expense',
          ),
        ];

      case TransactionType.transfer:
        return [
          _buildAccountDropdown(
            l10n,
            label: L10nKeys.ledgerTxEditorFromAccount,
          ),
          const SizedBox(height: 16),
          _buildToAccountDropdown(l10n),
          const SizedBox(height: 16),
          _buildAssetDropdown(l10n),
          const SizedBox(height: 16),
          _buildAmountField(l10n, L10nKeys.ledgerTxEditorAmount),
        ];

      case TransactionType.trade:
        return [
          _buildAccountDropdown(l10n),
          const SizedBox(height: 16),
          _buildFromAssetDropdown(l10n),
          const SizedBox(height: 16),
          _buildAmountField(
            l10n,
            L10nKeys.ledgerTxEditorAmountPaid,
            controller: _amountController,
          ),
          const SizedBox(height: 16),
          _buildToAssetDropdown(l10n),
          const SizedBox(height: 16),
          _buildAmountField(
            l10n,
            L10nKeys.ledgerTxEditorAmountReceived,
            controller: _toAmountController,
          ),
          const SizedBox(height: 16),
          _buildFeeAssetDropdown(l10n),
          if (_feeAsset != null) ...[
            const SizedBox(height: 16),
            _buildAmountField(
              l10n,
              L10nKeys.ledgerTxEditorFeeAmount,
              controller: _feeAmountController,
            ),
          ],
        ];

      case TransactionType.adjustment:
        return [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.get(L10nKeys.ledgerTxEditorAdjustmentHelper),
                    style: TextStyle(
                      color: Colors.orange.shade900,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildAccountDropdown(l10n),
          const SizedBox(height: 16),
          _buildAssetDropdown(l10n),
          const SizedBox(height: 16),
          _buildAmountField(l10n, L10nKeys.ledgerTxEditorAmount),
        ];
    }
  }

  Widget _buildAccountDropdown(LocalizationService l10n, {String label = ''}) {
    final labelText = label.isEmpty ? L10nKeys.ledgerTxEditorAccount : label;
    return DropdownButtonFormField<Account>(
      initialValue: _selectedAccount,
      decoration: InputDecoration(
        labelText: l10n.get(labelText),
        prefixIcon: const Icon(Icons.account_balance),
      ),
      items: _accounts
          .map(
            (account) =>
                DropdownMenuItem(value: account, child: Text(account.name)),
          )
          .toList(),
      onChanged: (account) => setState(() => _selectedAccount = account),
      validator: (value) => value == null
          ? l10n.get(L10nKeys.ledgerTxEditorAccountRequired)
          : null,
    );
  }

  Widget _buildToAccountDropdown(LocalizationService l10n) {
    return DropdownButtonFormField<Account>(
      initialValue: _toAccount,
      decoration: InputDecoration(
        labelText: l10n.get(L10nKeys.ledgerTxEditorToAccount),
        prefixIcon: const Icon(Icons.account_balance),
      ),
      items: _accounts
          .where((a) => a.id != _selectedAccount?.id)
          .map(
            (account) =>
                DropdownMenuItem(value: account, child: Text(account.name)),
          )
          .toList(),
      onChanged: (account) => setState(() => _toAccount = account),
      validator: (value) => value == null
          ? l10n.get(L10nKeys.ledgerTxEditorToAccountRequired)
          : null,
    );
  }

  Widget _buildAssetDropdown(LocalizationService l10n) {
    return DropdownButtonFormField<Asset>(
      initialValue: _selectedAsset,
      decoration: InputDecoration(
        labelText: l10n.get(L10nKeys.ledgerTxEditorAsset),
        prefixIcon: const Icon(Icons.attach_money),
      ),
      items: _assets
          .map(
            (asset) => DropdownMenuItem(
              value: asset,
              child: Text('${asset.symbol} - ${asset.name}'),
            ),
          )
          .toList(),
      onChanged: (asset) => setState(() => _selectedAsset = asset),
      validator: (value) =>
          value == null ? l10n.get(L10nKeys.ledgerTxEditorAssetRequired) : null,
    );
  }

  Widget _buildFromAssetDropdown(LocalizationService l10n) {
    return DropdownButtonFormField<Asset>(
      initialValue: _fromAsset,
      decoration: InputDecoration(
        labelText: l10n.get(L10nKeys.ledgerTxEditorFromAsset),
        prefixIcon: const Icon(Icons.attach_money),
      ),
      items: _assets
          .map(
            (asset) => DropdownMenuItem(
              value: asset,
              child: Text('${asset.symbol} - ${asset.name}'),
            ),
          )
          .toList(),
      onChanged: (asset) => setState(() => _fromAsset = asset),
      validator: (value) => value == null
          ? l10n.get(L10nKeys.ledgerTxEditorFromAssetRequired)
          : null,
    );
  }

  Widget _buildToAssetDropdown(LocalizationService l10n) {
    return DropdownButtonFormField<Asset>(
      initialValue: _toAsset,
      decoration: InputDecoration(
        labelText: l10n.get(L10nKeys.ledgerTxEditorToAsset),
        prefixIcon: const Icon(Icons.attach_money),
      ),
      items: _assets
          .where((a) => a.id != _fromAsset?.id)
          .map(
            (asset) => DropdownMenuItem(
              value: asset,
              child: Text('${asset.symbol} - ${asset.name}'),
            ),
          )
          .toList(),
      onChanged: (asset) => setState(() => _toAsset = asset),
      validator: (value) => value == null
          ? l10n.get(L10nKeys.ledgerTxEditorToAssetRequired)
          : null,
    );
  }

  Widget _buildFeeAssetDropdown(LocalizationService l10n) {
    return DropdownButtonFormField<Asset?>(
      initialValue: _feeAsset,
      decoration: InputDecoration(
        labelText: l10n.get(L10nKeys.ledgerTxEditorFeeAsset),
        hintText: l10n.get(L10nKeys.ledgerTxEditorFeeAssetHint),
        prefixIcon: const Icon(Icons.monetization_on),
      ),
      items: [
        DropdownMenuItem<Asset?>(
          value: null,
          child: Text(l10n.get(L10nKeys.ledgerTxEditorNoFee)),
        ),
        ..._assets.map(
          (asset) => DropdownMenuItem<Asset?>(
            value: asset,
            child: Text('${asset.symbol} - ${asset.name}'),
          ),
        ),
      ],
      onChanged: (asset) => setState(() => _feeAsset = asset),
    );
  }

  Widget _buildCategoryDropdown(LocalizationService l10n, String kind) {
    final filteredCategories = _categories
        .where((c) => c.kind.name == kind || c.kind == CategoryKind.mixed)
        .toList();

    return DropdownButtonFormField<Category>(
      initialValue: _selectedCategory,
      decoration: InputDecoration(
        labelText: l10n.get(L10nKeys.ledgerTxEditorCategory),
        prefixIcon: const Icon(Icons.category),
      ),
      items: filteredCategories
          .map(
            (category) => DropdownMenuItem<Category>(
              value: category,
              child: Text(category.name),
            ),
          )
          .toList(),
      onChanged: (category) => setState(() => _selectedCategory = category),
      validator: (value) {
        if (_type == TransactionType.expense && value == null) {
          return l10n.get(L10nKeys.ledgerTxEditorCategoryRequired);
        }
        return null;
      },
    );
  }

  Widget _buildAmountField(
    LocalizationService l10n,
    String labelKey, {
    TextEditingController? controller,
  }) {
    final isAdjustment = _type == TransactionType.adjustment;

    return TextFormField(
      controller: controller ?? _amountController,
      decoration: InputDecoration(
        labelText: l10n.get(labelKey),
        prefixIcon: const Icon(Icons.attach_money),
      ),
      keyboardType: TextInputType.numberWithOptions(
        decimal: true,
        signed: isAdjustment,
      ),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          isAdjustment ? RegExp(r'^-?\d*\.?\d*') : RegExp(r'^\d*\.?\d*'),
        ),
      ],
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return l10n.get(L10nKeys.ledgerTxEditorAmountRequired);
        }
        final amount = double.tryParse(value.trim());
        if (amount == null || (!isAdjustment && amount == 0)) {
          return l10n.get(L10nKeys.ledgerTxEditorAmountInvalid);
        }
        return null;
      },
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }
}
