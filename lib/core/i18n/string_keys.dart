/// Central registry of all localization keys
/// This ensures type-safe string references and prevents typos
class L10nKeys {
  // Common
  static const String appName = 'app.name';
  static const String ok = 'common.ok';
  static const String cancel = 'common.cancel';
  static const String retry = 'common.retry';
  static const String loading = 'common.loading';
  static const String error = 'common.error';
  static const String success = 'common.success';

  // Onboarding
  static const String onboardingTitle = 'onboarding.title';
  static const String onboardingSubtitle = 'onboarding.subtitle';
  static const String onboardingGetStarted = 'onboarding.get_started';
  static const String onboardingSkip = 'onboarding.skip';

  // Errors
  static const String errorNetworkOffline = 'error.network_offline';
  static const String errorTimeout = 'error.timeout';
  static const String errorServerError = 'error.server_error';
  static const String errorBadRequest = 'error.bad_request';
  static const String errorUnauthorized = 'error.unauthorized';
  static const String errorForbidden = 'error.forbidden';
  static const String errorNotFound = 'error.not_found';
  static const String errorInvalidCredentials = 'error.invalid_credentials';
  static const String errorSessionExpired = 'error.session_expired';
  static const String errorParseError = 'error.parse_error';
  static const String errorUnknown = 'error.unknown';
  static const String errorInlineTitle = 'error.inline_title';
  // Accessibility labels
  static const String a11yNavigationBack = 'a11y.navigation.back';
  static const String a11yNavigationMenu = 'a11y.navigation.menu';
  static const String a11yCloseButton = 'a11y.close_button';
  static const String a11yRefreshButton = 'a11y.refresh_button';
  static const String a11yLoadingIndicator = 'a11y.loading_indicator';
  static const String a11yErrorIcon = 'a11y.error_icon';
  static const String a11ySuccessIcon = 'a11y.success_icon';

  // Network status
  static const String networkOffline = 'network.offline';
  static const String networkOnline = 'network.online';
  static const String networkUnknown = 'network.unknown';

  // ------------------------------------------------------------
  // LedgerOne – App
  // ------------------------------------------------------------

  static const String ledgerAppTitle = 'ledger.app_title';

  static const String ledgerErrorStalePrice = 'ledger.error.stale_price';

  // LedgerOne – Onboarding
  static const String ledgerOnboardingWelcomeTitle =
      'ledger.onboarding.welcome_title';
  static const String ledgerOnboardingWelcomeSubtitle =
      'ledger.onboarding.welcome_subtitle';
  static const String ledgerOnboardingFeature1Title =
      'ledger.onboarding.feature1_title';
  static const String ledgerOnboardingFeature1Desc =
      'ledger.onboarding.feature1_desc';
  static const String ledgerOnboardingFeature2Title =
      'ledger.onboarding.feature2_title';
  static const String ledgerOnboardingFeature2Desc =
      'ledger.onboarding.feature2_desc';
  static const String ledgerOnboardingFeature3Title =
      'ledger.onboarding.feature3_title';
  static const String ledgerOnboardingFeature3Desc =
      'ledger.onboarding.feature3_desc';
  static const String ledgerOnboardingGetStarted =
      'ledger.onboarding.get_started';
  static const String ledgerOnboardingSkip = 'ledger.onboarding.skip';
  static const String ledgerOnboardingNext = 'ledger.onboarding.next';
  static const String ledgerOnboardingPrevious = 'ledger.onboarding.previous';

  // LedgerOne – Dashboard
  static const String ledgerDashboardTitle = 'ledger.dashboard.title';
  static const String ledgerDashboardTotalPortfolio =
      'ledger.dashboard.total_portfolio';
  static const String ledgerDashboardCrypto = 'ledger.dashboard.crypto';
  static const String ledgerDashboardFiat = 'ledger.dashboard.fiat';
  static const String ledgerDashboardTopHoldings =
      'ledger.dashboard.top_holdings';
  static const String ledgerDashboardQuickActions =
      'ledger.dashboard.quick_actions';
  static const String ledgerDashboardNoAssets = 'ledger.dashboard.no_assets';
  static const String ledgerDashboardUpdatePrices =
      'ledger.dashboard.update_prices';
  static const String ledgerDashboardUpdatingPrices =
      'ledger.dashboard.updating_prices';
  static const String ledgerDashboardPricesUpdated =
      'ledger.dashboard.prices_updated';
  static const String ledgerDashboardPriceUpdateFailed =
      'ledger.dashboard.price_update_failed';
  static const String ledgerDashboardLastUpdate =
      'ledger.dashboard.last_update';
  static const String ledgerDashboardJustNow = 'ledger.dashboard.just_now';
  static const String ledgerDashboardMinutesAgo =
      'ledger.dashboard.minutes_ago';
  static const String ledgerDashboardHoursAgo = 'ledger.dashboard.hours_ago';
  static const String ledgerDashboardDaysAgo = 'ledger.dashboard.days_ago';

  // LedgerOne – Navigation
  static const String ledgerNavDashboard = 'ledger.nav.dashboard';
  static const String ledgerNavCrypto = 'ledger.nav.crypto';
  static const String ledgerNavMoney = 'ledger.nav.money';
  static const String ledgerNavSettings = 'ledger.nav.settings';

  // LedgerOne – Quick Actions
  static const String ledgerActionAddTransaction =
      'ledger.action.add_transaction';
  static const String ledgerActionViewAccounts = 'ledger.action.view_accounts';
  static const String ledgerActionManageAssets = 'ledger.action.manage_assets';
  static const String ledgerActionBackupData = 'ledger.action.backup_data';

  // LedgerOne – Transaction Editor
  static const String ledgerTxEditorTitle = 'ledger.tx_editor.title';
  static const String ledgerTxEditorTitleEdit = 'ledger.tx_editor.title_edit';
  static const String ledgerTxEditorType = 'ledger.tx_editor.type';
  static const String ledgerTxEditorDescription =
      'ledger.tx_editor.description';
  static const String ledgerTxEditorDescriptionHint =
      'ledger.tx_editor.description_hint';
  static const String ledgerTxEditorDescriptionRequired =
      'ledger.tx_editor.description_required';
  static const String ledgerTxEditorDateTime = 'ledger.tx_editor.date_time';
  static const String ledgerTxEditorAccount = 'ledger.tx_editor.account';
  static const String ledgerTxEditorAccountRequired =
      'ledger.tx_editor.account_required';
  static const String ledgerTxEditorFromAccount =
      'ledger.tx_editor.from_account';
  static const String ledgerTxEditorToAccount = 'ledger.tx_editor.to_account';
  static const String ledgerTxEditorToAccountRequired =
      'ledger.tx_editor.to_account_required';
  static const String ledgerTxEditorAsset = 'ledger.tx_editor.asset';
  static const String ledgerTxEditorAssetRequired =
      'ledger.tx_editor.asset_required';
  static const String ledgerTxEditorFromAsset = 'ledger.tx_editor.from_asset';
  static const String ledgerTxEditorFromAssetRequired =
      'ledger.tx_editor.from_asset_required';
  static const String ledgerTxEditorToAsset = 'ledger.tx_editor.to_asset';
  static const String ledgerTxEditorToAssetRequired =
      'ledger.tx_editor.to_asset_required';
  static const String ledgerTxEditorFeeAsset = 'ledger.tx_editor.fee_asset';
  static const String ledgerTxEditorFeeAssetHint =
      'ledger.tx_editor.fee_asset_hint';
  static const String ledgerTxEditorNoFee = 'ledger.tx_editor.no_fee';
  static const String ledgerTxEditorAmount = 'ledger.tx_editor.amount';
  static const String ledgerTxEditorAmountRequired =
      'ledger.tx_editor.amount_required';
  static const String ledgerTxEditorAmountInvalid =
      'ledger.tx_editor.amount_invalid';
  static const String ledgerTxEditorAmountPaid = 'ledger.tx_editor.amount_paid';
  static const String ledgerTxEditorAmountReceived =
      'ledger.tx_editor.amount_received';
  static const String ledgerTxEditorFeeAmount = 'ledger.tx_editor.fee_amount';
  static const String ledgerTxEditorCategory = 'ledger.tx_editor.category';
  static const String ledgerTxEditorCategoryRequired =
      'ledger.tx_editor.category_required';
  static const String ledgerTxEditorAdjustmentHelper =
      'ledger.tx_editor.adjustment_helper';
  static const String ledgerTxEditorCreate = 'ledger.tx_editor.create';
  static const String ledgerTxEditorUpdate = 'ledger.tx_editor.update';
  static const String ledgerTxEditorCreated = 'ledger.tx_editor.created';
  static const String ledgerTxEditorUpdated = 'ledger.tx_editor.updated';

  // LedgerOne – Transaction Types
  static const String ledgerTxTypeIncome = 'ledger.tx_type.income';
  static const String ledgerTxTypeExpense = 'ledger.tx_type.expense';
  static const String ledgerTxTypeTransfer = 'ledger.tx_type.transfer';
  static const String ledgerTxTypeTrade = 'ledger.tx_type.trade';
  static const String ledgerTxTypeAdjustment = 'ledger.tx_type.adjustment';

  // LedgerOne – Crypto Screen
  static const String ledgerCryptoTitle = 'ledger.crypto.title';
  static const String ledgerCryptoByAsset = 'ledger.crypto.by_asset';
  static const String ledgerCryptoByAccount = 'ledger.crypto.by_account';
  static const String ledgerCryptoNoAssets = 'ledger.crypto.no_assets';
  static const String ledgerCryptoNoAccounts = 'ledger.crypto.no_accounts';
  static const String ledgerCryptoTotalValue = 'ledger.crypto.total_value';
  static const String ledgerCryptoAssets = 'ledger.crypto.assets';

  // LedgerOne – Money Screen
  static const String ledgerMoneyTitle = 'ledger.money.title';
  static const String ledgerMoneyAccounts = 'ledger.money.accounts';
  static const String ledgerMoneyTransactions = 'ledger.money.transactions';
  static const String ledgerMoneyCategories = 'ledger.money.categories';
  static const String ledgerMoneyNoAccounts = 'ledger.money.no_accounts';
  static const String ledgerMoneyNoTransactions =
      'ledger.money.no_transactions';
  static const String ledgerMoneyThisMonth = 'ledger.money.this_month';
  static const String ledgerMoneyTotalIncome = 'ledger.money.total_income';
  static const String ledgerMoneyTotalExpenses = 'ledger.money.total_expenses';
  static const String ledgerMoneyNetIncome = 'ledger.money.net_income';

  // LedgerOne – Settings
  static const String ledgerSettingsTitle = 'ledger.settings.title';
  static const String ledgerSettingsGeneral = 'ledger.settings.general';
  static const String ledgerSettingsLanguage = 'ledger.settings.language';
  static const String ledgerSettingsTheme = 'ledger.settings.theme';
  static const String ledgerSettingsThemeLight = 'ledger.settings.theme_light';
  static const String ledgerSettingsThemeDark = 'ledger.settings.theme_dark';
  static const String ledgerSettingsThemeSystem =
      'ledger.settings.theme_system';
  static const String ledgerSettingsData = 'ledger.settings.data';
  static const String ledgerSettingsBackup = 'ledger.settings.backup';
  static const String ledgerSettingsRestore = 'ledger.settings.restore';
  static const String ledgerSettingsExport = 'ledger.settings.export';
  static const String ledgerSettingsAbout = 'ledger.settings.about';
  static const String ledgerSettingsVersion = 'ledger.settings.version';

  // LedgerOne – Common
  static const String ledgerCommonSave = 'ledger.common.save';
  static const String ledgerCommonCancel = 'ledger.common.cancel';
  static const String ledgerCommonDelete = 'ledger.common.delete';
  static const String ledgerCommonEdit = 'ledger.common.edit';
  static const String ledgerCommonAdd = 'ledger.common.add';
  static const String ledgerCommonClose = 'ledger.common.close';
  static const String ledgerCommonConfirm = 'ledger.common.confirm';
  static const String ledgerCommonBalance = 'ledger.common.balance';
  static const String ledgerCommonAccounts = 'ledger.common.accounts';
  static const String ledgerCommonAssets = 'ledger.common.assets';
  static const String ledgerCommonNoData = 'ledger.common.no_data';
  static const String ledgerCommonLoading = 'ledger.common.loading';
  static const String ledgerCommonLoadingData = 'ledger.common.loading_data';

  // LedgerOne – Accessibility
  static const String ledgerA11yUpdatePrices = 'ledger.a11y.update_prices';
  static const String ledgerA11yNavigateBack = 'ledger.a11y.navigate_back';
  static const String ledgerA11yOpenSettings = 'ledger.a11y.open_settings';
  static const String ledgerA11ySelectDate = 'ledger.a11y.select_date';
  static const String ledgerA11ySelectTime = 'ledger.a11y.select_time';
  static const String ledgerA11yAssetIcon = 'ledger.a11y.asset_icon';
  static const String ledgerA11yAccountIcon = 'ledger.a11y.account_icon';
}
