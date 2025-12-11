import 'dart:async';

/// Service for backing up and restoring all LedgerOne data using JSON.
abstract interface class BackupService {
  /// Serialize all ledger data into a JSON string.
  ///
  /// The returned string is a self-contained backup you can save as a .json file.
  Future<String> exportToJson();

  /// Restore all ledger data from a JSON string created by [exportToJson].
  ///
  /// If [clearExisting] is true (default), existing data is wiped first.
  /// Callers **must** ask the user for confirmation before calling with
  /// [clearExisting] = true.
  Future<void> restoreFromJson(String json, {bool clearExisting = true});
}
