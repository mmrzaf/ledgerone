import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/contracts/navigation_contract.dart';
import '../data/database.dart';
import '../domain/models.dart';

class TransactionEditorScreen extends StatefulWidget {
  final NavigationService navigation;
  final LedgerDatabase database;
  final AssetRepository assetRepo;
  final AccountRepository accountRepo;
  final CategoryRepository categoryRepo;
  final TransactionRepository transactionRepo;
  final Transaction? existingTransaction;
  final List<TransactionLeg>? existingLegs;

  const TransactionEditorScreen({
    required this.navigation,
    required this.database,
    required this.assetRepo,
    required this.accountRepo,
    required this.categoryRepo,
    required this.transactionRepo,
    this.existingTransaction,
    this.existingLegs,
    super.key,
  });

  @override
  State<TransactionEditorScreen> createState() =>
      _TransactionEditorScreenState();
}

class _TransactionEditorScreenState extends State<TransactionEditorScreen> {
  final _formKey = GlobalKey<FormState>();

  // Common fields
  TransactionType _type = TransactionType.expense;
  DateTime _timestamp = DateTime.now();
  final _descriptionController = TextEditingController();

  // Type-specific fields
  Account? _selectedAccount;
  Account? _toAccount; // For transfers
  Asset? _selectedAsset;
  Asset? _fromAsset; // For trades
  Asset? _toAsset; // For trades
  Asset? _feeAsset; // For trades
  Category? _selectedCategory;

  final _amountController = TextEditingController();
  final _toAmountController = TextEditingController(); // For trades
  final _feeAmountController = TextEditingController();

  List<Asset> _assets = [];
  List<Account> _accounts = [];
  List<Category> _categories = [];

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadData();

    if (widget.existingTransaction != null) {
      _loadExistingTransaction();
    }
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
    final assets = await widget.assetRepo.getAll();
    final accounts = await widget.accountRepo.getAll();
    final categories = await widget.categoryRepo.getAll();

    setState(() {
      _assets = assets;
      _accounts = accounts;
      _categories = categories;
      _loading = false;
    });

    if (widget.existingTransaction != null && widget.existingLegs != null) {
      _loadExistingTransaction();
    }
  }

  void _loadExistingTransaction() {
    if (_assets.isEmpty || _accounts.isEmpty) return;

    final tx = widget.existingTransaction;
    final legs = widget.existingLegs ?? const <TransactionLeg>[];

    if (tx == null || legs.isEmpty) return;

    setState(() {
      _type = tx.type;
      _timestamp = tx.timestamp;
      _descriptionController.text = tx.description;

      switch (_type) {
        case TransactionType.transfer:
          final fromLeg = legs.firstWhere(
            (l) => l.amount < 0,
            orElse: () => legs.first,
          );
          final toLeg = legs.firstWhere(
            (l) => l.amount > 0,
            orElse: () => legs.first,
          );

          _selectedAccount = _accounts.firstWhere(
            (a) => a.id == fromLeg.accountId,
            orElse: () => _accounts.first,
          );

          _toAccount = _accounts.firstWhere(
            (a) => a.id == toLeg.accountId,
            orElse: () => _accounts.first,
          );

          _selectedAsset = _assets.firstWhere(
            (a) => a.id == fromLeg.assetId,
            orElse: () => _assets.first,
          );

          _amountController.text = fromLeg.amount.abs().toString();
          break;

        case TransactionType.trade:
          final fromLeg = legs.firstWhere(
            (l) => l.role == LegRole.main && l.amount < 0,
            orElse: () =>
                legs.firstWhere((l) => l.amount < 0, orElse: () => legs.first),
          );

          final toLeg = legs.firstWhere(
            (l) => l.role == LegRole.main && l.amount > 0,
            orElse: () =>
                legs.firstWhere((l) => l.amount > 0, orElse: () => legs.first),
          );

          final feeLeg = legs.where((l) => l.role == LegRole.fee).firstOrNull;

          _selectedAccount = _accounts.firstWhere(
            (a) => a.id == fromLeg.accountId,
            orElse: () => _accounts.first,
          );

          _fromAsset = _assets.firstWhere(
            (a) => a.id == fromLeg.assetId,
            orElse: () => _assets.first,
          );

          _toAsset = _assets.firstWhere(
            (a) => a.id == toLeg.assetId,
            orElse: () => _assets.first,
          );

          _amountController.text = fromLeg.amount.abs().toString();
          _toAmountController.text = toLeg.amount.abs().toString();

          if (feeLeg != null) {
            _feeAsset = _assets.firstWhere(
              (a) => a.id == feeLeg.assetId,
              orElse: () => _assets.first,
            );
            _feeAmountController.text = feeLeg.amount.abs().toString();
          }
          break;

        default:
          // income / expense / adjustment → main-leg + category logic
          final mainLeg = legs.firstWhere(
            (l) => l.role == LegRole.main,
            orElse: () => legs.first,
          );

          _selectedAccount = _accounts.firstWhere(
            (a) => a.id == mainLeg.accountId,
            orElse: () => _accounts.first,
          );

          _selectedAsset = _assets.firstWhere(
            (a) => a.id == mainLeg.assetId,
            orElse: () => _assets.first,
          );

          _amountController.text = mainLeg.amount.abs().toString();

          if (mainLeg.categoryId != null && _categories.isNotEmpty) {
            _selectedCategory = _categories.firstWhere(
              (c) => c.id == mainLeg.categoryId,
              orElse: () => _categories.first,
            );
          }
          break;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final transaction = Transaction(
        id: widget.existingTransaction?.id ?? widget.database.generateId(),
        timestamp: _timestamp,
        type: _type,
        description: _descriptionController.text.trim(),
        createdAt: widget.existingTransaction?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final legs = _buildLegs(transaction.id);

      if (widget.existingTransaction != null) {
        await widget.transactionRepo.update(transaction, legs);
      } else {
        await widget.transactionRepo.insert(transaction, legs);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existingTransaction != null
                  ? 'Transaction updated'
                  : 'Transaction created',
            ),
            backgroundColor: Colors.green,
          ),
        );
        widget.navigation.goBack();
      }
    } catch (e) {
      setState(() => _saving = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  List<TransactionLeg> _buildLegs(String transactionId) {
    final legs = <TransactionLeg>[];

    switch (_type) {
      case TransactionType.income:
        legs.add(
          TransactionLeg(
            id: widget.database.generateId(),
            transactionId: transactionId,
            accountId: _selectedAccount!.id,
            assetId: _selectedAsset!.id,
            amount: _parseAmount(_amountController.text), // Positive
            role: LegRole.main,
            categoryId: _selectedCategory?.id,
          ),
        );
        break;

      case TransactionType.expense:
        legs.add(
          TransactionLeg(
            id: widget.database.generateId(),
            transactionId: transactionId,
            accountId: _selectedAccount!.id,
            assetId: _selectedAsset!.id,
            amount: -_parseAmount(_amountController.text), // Negative
            role: LegRole.main,
            categoryId: _selectedCategory?.id,
          ),
        );
        break;

      case TransactionType.transfer:
        // Negative leg (from)
        legs.add(
          TransactionLeg(
            id: widget.database.generateId(),
            transactionId: transactionId,
            accountId: _selectedAccount!.id,
            assetId: _selectedAsset!.id,
            amount: -_parseAmount(_amountController.text),
            role: LegRole.main,
          ),
        );

        // Positive leg (to)
        legs.add(
          TransactionLeg(
            id: widget.database.generateId(),
            transactionId: transactionId,
            accountId: _toAccount!.id,
            assetId: _selectedAsset!.id,
            amount: _parseAmount(_amountController.text),
            role: LegRole.main,
          ),
        );
        break;

      case TransactionType.trade:
        // What you pay (negative)
        legs.add(
          TransactionLeg(
            id: widget.database.generateId(),
            transactionId: transactionId,
            accountId: _selectedAccount!.id,
            assetId: _fromAsset!.id,
            amount: -_parseAmount(_amountController.text),
            role: LegRole.main,
          ),
        );

        // What you receive (positive)
        legs.add(
          TransactionLeg(
            id: widget.database.generateId(),
            transactionId: transactionId,
            accountId: _selectedAccount!.id,
            assetId: _toAsset!.id,
            amount: _parseAmount(_toAmountController.text),
            role: LegRole.main,
          ),
        );

        // Optional fee
        if (_feeAsset != null && _feeAmountController.text.isNotEmpty) {
          legs.add(
            TransactionLeg(
              id: widget.database.generateId(),
              transactionId: transactionId,
              accountId: _selectedAccount!.id,
              assetId: _feeAsset!.id,
              amount: -_parseAmount(_feeAmountController.text),
              role: LegRole.fee,
            ),
          );
        }
        break;

      case TransactionType.adjustment:
        legs.add(
          TransactionLeg(
            id: widget.database.generateId(),
            transactionId: transactionId,
            accountId: _selectedAccount!.id,
            assetId: _selectedAsset!.id,
            amount: _parseAmount(_amountController.text),
            role: LegRole.main,
          ),
        );
        break;
    }

    return legs;
  }

  double _parseAmount(String text) {
    return double.tryParse(text.trim()) ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingTransaction != null
              ? 'Edit Transaction'
              : 'New Transaction',
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
              tooltip: 'Save',
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildTypeSelector(theme),
                  const SizedBox(height: 24),
                  _buildDateTimePicker(theme),
                  const SizedBox(height: 16),
                  _buildDescriptionField(),
                  const SizedBox(height: 24),
                  ..._buildTypeSpecificFields(theme),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      child: Text(
                        widget.existingTransaction != null
                            ? 'Update Transaction'
                            : 'Create Transaction',
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTypeSelector(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Transaction Type', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        SegmentedButton<TransactionType>(
          segments: TransactionType.values
              .map(
                (type) => ButtonSegment(
                  value: type,
                  label: Text(type.displayName),
                  icon: Icon(_getTypeIcon(type)),
                ),
              )
              .toList(),
          selected: {_type},
          onSelectionChanged: (Set<TransactionType> selected) {
            setState(() => _type = selected.first);
          },
        ),
      ],
    );
  }

  IconData _getTypeIcon(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return Icons.arrow_downward;
      case TransactionType.expense:
        return Icons.arrow_upward;
      case TransactionType.transfer:
        return Icons.swap_horiz;
      case TransactionType.trade:
        return Icons.currency_exchange;
      case TransactionType.adjustment:
        return Icons.tune;
    }
  }

  Widget _buildDateTimePicker(ThemeData theme) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.calendar_today),
      title: const Text('Date & Time'),
      subtitle: Text(_formatDateTime(_timestamp)),
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
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: const InputDecoration(
        labelText: 'Description',
        hintText: 'Enter transaction description',
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Description is required';
        }
        return null;
      },
    );
  }

  List<Widget> _buildTypeSpecificFields(ThemeData theme) {
    switch (_type) {
      case TransactionType.income:
      case TransactionType.expense:
        return [
          _buildAccountDropdown(),
          const SizedBox(height: 16),
          _buildAssetDropdown(),
          const SizedBox(height: 16),
          _buildAmountField('Amount'),
          const SizedBox(height: 16),
          _buildCategoryDropdown(
            _type == TransactionType.income ? 'income' : 'expense',
          ),
        ];

      case TransactionType.transfer:
        return [
          _buildAccountDropdown(label: 'From Account'),
          const SizedBox(height: 16),
          _buildToAccountDropdown(),
          const SizedBox(height: 16),
          _buildAssetDropdown(),
          const SizedBox(height: 16),
          _buildAmountField('Amount'),
        ];

      case TransactionType.trade:
        return [
          _buildAccountDropdown(),
          const SizedBox(height: 16),
          _buildFromAssetDropdown(),
          const SizedBox(height: 16),
          _buildAmountField('Amount Paid', controller: _amountController),
          const SizedBox(height: 16),
          _buildToAssetDropdown(),
          const SizedBox(height: 16),
          _buildAmountField('Amount Received', controller: _toAmountController),
          const SizedBox(height: 16),
          _buildFeeAssetDropdown(),
          if (_feeAsset != null) ...[
            const SizedBox(height: 16),
            _buildAmountField('Fee Amount', controller: _feeAmountController),
          ],
        ];

      case TransactionType.adjustment:
        return [
          _buildAccountDropdown(),
          const SizedBox(height: 16),
          _buildAssetDropdown(),
          const SizedBox(height: 16),
          _buildAmountField(
            'Amount',
            helperText: 'Positive increases balance, negative decreases',
          ),
        ];
    }
  }

  Widget _buildAccountDropdown({String label = 'Account'}) {
    return DropdownButtonFormField<Account>(
      initialValue: _selectedAccount,
      decoration: InputDecoration(labelText: label),
      items: _accounts
          .map(
            (account) =>
                DropdownMenuItem(value: account, child: Text(account.name)),
          )
          .toList(),
      onChanged: (account) => setState(() => _selectedAccount = account),
      validator: (value) => value == null ? 'Account is required' : null,
    );
  }

  Widget _buildToAccountDropdown() {
    return DropdownButtonFormField<Account>(
      initialValue: _toAccount,
      decoration: const InputDecoration(labelText: 'To Account'),
      items: _accounts
          .where((a) => a.id != _selectedAccount?.id)
          .map(
            (account) =>
                DropdownMenuItem(value: account, child: Text(account.name)),
          )
          .toList(),
      onChanged: (account) => setState(() => _toAccount = account),
      validator: (value) => value == null ? 'To account is required' : null,
    );
  }

  Widget _buildAssetDropdown() {
    return DropdownButtonFormField<Asset>(
      initialValue: _selectedAsset,
      decoration: const InputDecoration(labelText: 'Asset'),
      items: _assets
          .map(
            (asset) => DropdownMenuItem(
              value: asset,
              child: Text('${asset.symbol} - ${asset.name}'),
            ),
          )
          .toList(),
      onChanged: (asset) => setState(() => _selectedAsset = asset),
      validator: (value) => value == null ? 'Asset is required' : null,
    );
  }

  Widget _buildFromAssetDropdown() {
    return DropdownButtonFormField<Asset>(
      initialValue: _fromAsset,
      decoration: const InputDecoration(labelText: 'From Asset (Paying)'),
      items: _assets
          .map(
            (asset) => DropdownMenuItem(
              value: asset,
              child: Text('${asset.symbol} - ${asset.name}'),
            ),
          )
          .toList(),
      onChanged: (asset) => setState(() => _fromAsset = asset),
      validator: (value) => value == null ? 'From asset is required' : null,
    );
  }

  Widget _buildToAssetDropdown() {
    return DropdownButtonFormField<Asset>(
      initialValue: _toAsset,
      decoration: const InputDecoration(labelText: 'To Asset (Receiving)'),
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
      validator: (value) => value == null ? 'To asset is required' : null,
    );
  }

  Widget _buildFeeAssetDropdown() {
    return DropdownButtonFormField<Asset>(
      initialValue: _feeAsset,
      decoration: const InputDecoration(
        labelText: 'Fee Asset (Optional)',
        hintText: 'Select if there was a fee',
      ),
      items: [
        const DropdownMenuItem<Asset>(value: null, child: Text('No fee')),
        ..._assets.map(
          (asset) => DropdownMenuItem(
            value: asset,
            child: Text('${asset.symbol} - ${asset.name}'),
          ),
        ),
      ],
      onChanged: (asset) => setState(() => _feeAsset = asset),
    );
  }

  Widget _buildCategoryDropdown(String kind) {
    final filteredCategories = _categories
        .where((c) => c.kind.name == kind || c.kind == CategoryKind.mixed)
        .toList();

    return DropdownButtonFormField<Category>(
      initialValue: _selectedCategory,
      decoration: const InputDecoration(labelText: 'Category'),
      items: filteredCategories
          .map(
            (category) =>
                DropdownMenuItem(value: category, child: Text(category.name)),
          )
          .toList(),
      onChanged: (category) => setState(() => _selectedCategory = category),
      validator: (value) {
        if (_type == TransactionType.expense && value == null) {
          return 'Category is required for expenses';
        }
        return null;
      },
    );
  }

  Widget _buildAmountField(
    String label, {
    TextEditingController? controller,
    String? helperText,
  }) {
    return TextFormField(
      controller: controller ?? _amountController,
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        prefixIcon: const Icon(Icons.attach_money),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Amount is required';
        }
        final amount = double.tryParse(value.trim());
        if (amount == null || amount == 0) {
          return 'Enter a valid amount';
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
