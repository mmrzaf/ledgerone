import 'package:flutter/foundation.dart';

/// Asset types
enum AssetType {
  crypto,
  fiat,
  other;

  String get displayName => name[0].toUpperCase() + name.substring(1);
}

/// Account types
enum AccountType {
  exchange,
  bank,
  wallet,
  cash,
  other;

  String get displayName => name[0].toUpperCase() + name.substring(1);
}

/// Category kinds
enum CategoryKind {
  expense,
  income,
  transfer,
  mixed;

  String get displayName => name[0].toUpperCase() + name.substring(1);
}

/// Transaction types
enum TransactionType {
  trade,
  transfer,
  income,
  expense,
  adjustment;

  String get displayName => name[0].toUpperCase() + name.substring(1);
}

/// Leg roles
enum LegRole {
  main,
  fee,
  gas,
  tax,
  other;

  String get displayName => name[0].toUpperCase() + name.substring(1);
}

/// Asset - represents any unit of value tracked
@immutable
class Asset {
  final String id;
  final String symbol;
  final String name;
  final AssetType type;
  final int decimals;
  final String? priceSourceConfig; // JSON config for fetching price
  final DateTime createdAt;
  final DateTime updatedAt;

  const Asset({
    required this.id,
    required this.symbol,
    required this.name,
    required this.type,
    required this.decimals,
    this.priceSourceConfig,
    required this.createdAt,
    required this.updatedAt,
  });
  Asset copyWith({
    String? id,
    String? symbol,
    String? name,
    AssetType? type,
    int? decimals,
    String? priceSourceConfig,
    DateTime? updatedAt,
  }) {
    return Asset(
      id: id ?? this.id,
      symbol: symbol ?? this.symbol,
      name: name ?? this.name,
      type: type ?? this.type,
      decimals: decimals ?? this.decimals,
      priceSourceConfig: priceSourceConfig ?? this.priceSourceConfig,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'symbol': symbol,
    'name': name,
    'type': type.name,
    'decimals': decimals,
    'price_source_config': priceSourceConfig,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory Asset.fromJson(Map<String, dynamic> json) => Asset(
    id: json['id'] as String,
    symbol: json['symbol'] as String,
    name: json['name'] as String,
    type: AssetType.values.byName(json['type'] as String),
    decimals: json['decimals'] as int,
    priceSourceConfig: json['price_source_config'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
  );
}

/// Account - represents where assets live
@immutable
class Account {
  final String id;
  final String name;
  final AccountType type;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Account({
    required this.id,
    required this.name,
    required this.type,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });
  Account copyWith({
    String? id,
    String? name,
    AccountType? type,
    String? notes,
    DateTime? updatedAt,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    'notes': notes,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory Account.fromJson(Map<String, dynamic> json) => Account(
    id: json['id'] as String,
    name: json['name'] as String,
    type: AccountType.values.byName(json['type'] as String),
    notes: json['notes'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
  );
}

/// Category - for income/expense classification
@immutable
class Category {
  final String id;
  final String name;
  final CategoryKind kind;
  final String? parentId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Category({
    required this.id,
    required this.name,
    required this.kind,
    this.parentId,
    required this.createdAt,
    required this.updatedAt,
  });

  Category copyWith({
    String? name,
    CategoryKind? kind,
    String? parentId,
    DateTime? updatedAt,
  }) {
    return Category(
      id: id,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      parentId: parentId ?? this.parentId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'kind': kind.name,
    'parent_id': parentId,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: json['id'] as String,
    name: json['name'] as String,
    kind: CategoryKind.values.byName(json['kind'] as String),
    parentId: json['parent_id'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
  );
}

/// Transaction - logical event at a specific time
@immutable
class Transaction {
  final String id;
  final DateTime timestamp;
  final TransactionType type;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Transaction({
    required this.id,
    required this.timestamp,
    required this.type,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  Transaction copyWith({
    DateTime? timestamp,
    TransactionType? type,
    String? description,
    DateTime? updatedAt,
  }) {
    return Transaction(
      id: id,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      description: description ?? this.description,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'type': type.name,
    'description': description,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
    id: json['id'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
    type: TransactionType.values.byName(json['type'] as String),
    description: json['description'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
  );
}

/// Transaction Leg - balance delta for single asset in an account
@immutable
class TransactionLeg {
  final String id;
  final String transactionId;
  final String accountId;
  final String assetId;
  final double amount; // Positive = increase, Negative = decrease
  final LegRole role;
  final String? categoryId;

  const TransactionLeg({
    required this.id,
    required this.transactionId,
    required this.accountId,
    required this.assetId,
    required this.amount,
    required this.role,
    this.categoryId,
  });

  TransactionLeg copyWith({
    String? transactionId,
    String? accountId,
    String? assetId,
    double? amount,
    LegRole? role,
    String? categoryId,
  }) {
    return TransactionLeg(
      id: id,
      transactionId: transactionId ?? this.transactionId,
      accountId: accountId ?? this.accountId,
      assetId: assetId ?? this.assetId,
      amount: amount ?? this.amount,
      role: role ?? this.role,
      categoryId: categoryId ?? this.categoryId,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'transaction_id': transactionId,
    'account_id': accountId,
    'asset_id': assetId,
    'amount': amount,
    'role': role.name,
    'category_id': categoryId,
  };

  factory TransactionLeg.fromJson(Map<String, dynamic> json) => TransactionLeg(
    id: json['id'] as String,
    transactionId: json['transaction_id'] as String,
    accountId: json['account_id'] as String,
    assetId: json['asset_id'] as String,
    amount: (json['amount'] as num).toDouble(),
    role: LegRole.values.byName(json['role'] as String),
    categoryId: json['category_id'] as String?,
  );
}

/// Price Snapshot - stored price at specific time
@immutable
class PriceSnapshot {
  final String id;
  final String assetId;
  final String currencyCode; // e.g., "USD"
  final double price; // Price of 1 unit of asset in currency
  final DateTime timestamp;
  final String? source; // e.g., "coingecko"

  const PriceSnapshot({
    required this.id,
    required this.assetId,
    required this.currencyCode,
    required this.price,
    required this.timestamp,
    this.source,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'asset_id': assetId,
    'currency_code': currencyCode,
    'price': price,
    'timestamp': timestamp.toIso8601String(),
    'source': source,
  };

  factory PriceSnapshot.fromJson(Map<String, dynamic> json) => PriceSnapshot(
    id: json['id'] as String,
    assetId: json['asset_id'] as String,
    currencyCode: json['currency_code'] as String,
    price: (json['price'] as num).toDouble(),
    timestamp: DateTime.parse(json['timestamp'] as String),
    source: json['source'] as String?,
  );
}

/// Balance summary for an asset in an account
@immutable
class AssetBalance {
  final String assetId;
  final String accountId;
  final double balance;
  final Asset asset;
  final Account account;

  const AssetBalance({
    required this.assetId,
    required this.accountId,
    required this.balance,
    required this.asset,
    required this.account,
  });
}

/// Total balance across all accounts for an asset
@immutable
class TotalAssetBalance {
  final Asset asset;
  final double totalBalance;
  final double? usdValue; // null if no price available
  final List<AssetBalance> accountBalances;

  const TotalAssetBalance({
    required this.asset,
    required this.totalBalance,
    this.usdValue,
    required this.accountBalances,
  });
}

/// Price source configuration
@immutable
class PriceSourceConfig {
  final String method; // GET, POST
  final String url;
  final Map<String, String> queryParams;
  final Map<String, String> headers;
  final String responsePath; // Dot notation: "data.price"
  final double multiplier;

  const PriceSourceConfig({
    required this.method,
    required this.url,
    this.queryParams = const {},
    this.headers = const {},
    required this.responsePath,
    this.multiplier = 1.0,
  });

  Map<String, dynamic> toJson() => {
    'method': method,
    'url': url,
    'query_params': queryParams,
    'headers': headers,
    'response_path': responsePath,
    'multiplier': multiplier,
  };

  factory PriceSourceConfig.fromJson(Map<String, dynamic> json) =>
      PriceSourceConfig(
        method: json['method'] as String? ?? 'GET',
        url: json['url'] as String,
        queryParams: Map<String, String>.from(
          (json['query_params'] as Map?) ?? {},
        ),
        headers: Map<String, String>.from((json['headers'] as Map?) ?? {}),
        responsePath: json['response_path'] as String,
        multiplier: (json['multiplier'] as num?)?.toDouble() ?? 1.0,
      );
}
