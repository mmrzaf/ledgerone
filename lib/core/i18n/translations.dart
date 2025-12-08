/// English translations (base language)
const Map<String, String> translationsEn = {
  // Common
  'app.name': 'LedgerOne',
  'common.ok': 'OK',
  'common.cancel': 'Cancel',
  'common.retry': 'Try again',
  'common.loading': 'Loading...',
  'common.error': 'Error',
  'common.success': 'Success',

  // Onboarding
  'onboarding.title': 'Welcome',
  'onboarding.subtitle':
      'A production-ready Flutter starter with navigation, guards, and clean architecture.',
  'onboarding.get_started': 'Get started',
  'onboarding.skip': 'Skip',

  // Errors
  'error.network_offline':
      'No internet connection. Check your network and try again.',
  'error.timeout': 'The request timed out. Please try again.',
  'error.server_error': 'Server error. Please try again later.',
  'error.bad_request': 'Invalid request. Check your input and try again.',
  'error.unauthorized': 'Your session has expired. Please sign in again.',
  'error.forbidden': 'You don’t have permission to do that.',
  'error.not_found': 'The requested resource was not found.',
  'error.invalid_credentials': 'Incorrect email or password.',
  'error.session_expired': 'Your session has expired. Please sign in again.',
  'error.parse_error': 'We couldn’t process the response. Please try again.',
  'error.unknown': 'Something went wrong. Please try again.',
  'error.inline_title': 'Something went wrong',

  // Accessibility labels
  'a11y.navigation.back': 'Navigate back',
  'a11y.navigation.menu': 'Open menu',
  'a11y.close_button': 'Close',
  'a11y.refresh_button': 'Refresh content',
  'a11y.loading_indicator': 'Loading',
  'a11y.error_icon': 'Error',
  'a11y.success_icon': 'Success',

  // Network status
  'network.offline': 'No internet connection',
  'network.online': 'Connected',
  'network.unknown': 'Connection status unknown',

  // ------------------------------------------------------------
  // LedgerOne – App & Onboarding
  // ------------------------------------------------------------
  'ledger.app_title': 'LedgerOne',

  // LedgerOne – Errors
  'ledger.error.stale_price':
      'Price data is out of date. Update prices and try again.',

  'ledger.onboarding.welcome_title': 'Welcome to LedgerOne',
  'ledger.onboarding.welcome_subtitle':
      'Your private, offline-first tracker for finance and crypto.',
  'ledger.onboarding.feature1_title': 'Track everything',
  'ledger.onboarding.feature1_desc':
      'Manage crypto and cash in one place. See every asset across all your accounts.',
  'ledger.onboarding.feature2_title': 'Offline first',
  'ledger.onboarding.feature2_desc':
      'Works fully offline. Your data stays on your device. Prices update only when you decide.',
  'ledger.onboarding.feature3_title': 'Full control',
  'ledger.onboarding.feature3_desc':
      'No automatic syncing or hidden connections. You decide what happens. Export and back up anytime.',
  'ledger.onboarding.get_started': 'Get started',
  'ledger.onboarding.skip': 'Skip',
  'ledger.onboarding.next': 'Next',
  'ledger.onboarding.previous': 'Previous',

  // LedgerOne – Dashboard
  'ledger.dashboard.title': 'Dashboard',
  'ledger.dashboard.total_portfolio': 'Total portfolio',
  'ledger.dashboard.crypto': 'Crypto',
  'ledger.dashboard.fiat': 'Fiat',
  'ledger.dashboard.top_holdings': 'Top holdings',
  'ledger.dashboard.quick_actions': 'Quick actions',
  'ledger.dashboard.no_assets':
      'No assets yet. Add your first transaction to see your portfolio.',
  'ledger.dashboard.update_prices': 'Update prices',
  'ledger.dashboard.updating_prices': 'Updating prices...',
  'ledger.dashboard.prices_updated':
      'Updated {success} prices; {failed} failed.',
  'ledger.dashboard.price_update_failed': 'Price update failed.',
  'ledger.dashboard.last_update': 'Updated {time}',
  'ledger.dashboard.just_now': 'just now',
  'ledger.dashboard.minutes_ago': '{minutes} min ago',
  'ledger.dashboard.hours_ago': '{hours} hr ago',
  'ledger.dashboard.days_ago': '{days} days ago',

  // LedgerOne – Navigation
  'ledger.nav.dashboard': 'Dashboard',
  'ledger.nav.crypto': 'Crypto',
  'ledger.nav.money': 'Money',
  'ledger.nav.settings': 'Settings',

  // LedgerOne – Quick Actions
  'ledger.action.add_transaction': 'Add transaction',
  'ledger.action.view_accounts': 'View accounts',
  'ledger.action.manage_assets': 'Manage assets',
  'ledger.action.backup_data': 'Back up data',

  // LedgerOne – Transaction Editor
  'ledger.tx_editor.title': 'New transaction',
  'ledger.tx_editor.title_edit': 'Edit transaction',
  'ledger.tx_editor.type': 'Transaction type',
  'ledger.tx_editor.description': 'Description',
  'ledger.tx_editor.description_hint':
      'Add a short description for this transaction',
  'ledger.tx_editor.description_required': 'Description is required',
  'ledger.tx_editor.date_time': 'Date & time',
  'ledger.tx_editor.account': 'Account',
  'ledger.tx_editor.account_required': 'Account is required',
  'ledger.tx_editor.from_account': 'From account',
  'ledger.tx_editor.to_account': 'To account',
  'ledger.tx_editor.to_account_required': 'Destination account is required',
  'ledger.tx_editor.asset': 'Asset',
  'ledger.tx_editor.asset_required': 'Asset is required',
  'ledger.tx_editor.from_asset': 'From asset (paying)',
  'ledger.tx_editor.from_asset_required': 'From asset is required',
  'ledger.tx_editor.to_asset': 'To asset (receiving)',
  'ledger.tx_editor.to_asset_required': 'To asset is required',
  'ledger.tx_editor.fee_asset': 'Fee asset (optional)',
  'ledger.tx_editor.fee_asset_hint':
      'Select the asset used to pay the fee, if any',
  'ledger.tx_editor.no_fee': 'No fee',
  'ledger.tx_editor.amount': 'Amount',
  'ledger.tx_editor.amount_required': 'Amount is required',
  'ledger.tx_editor.amount_invalid': 'Enter a valid amount',
  'ledger.tx_editor.amount_paid': 'Amount paid',
  'ledger.tx_editor.amount_received': 'Amount received',
  'ledger.tx_editor.fee_amount': 'Fee amount',
  'ledger.tx_editor.category': 'Category',
  'ledger.tx_editor.category_required':
      'Category is required for expense transactions',
  'ledger.tx_editor.adjustment_helper':
      'Positive values increase the balance; negative values decrease it.',
  'ledger.tx_editor.create': 'Create transaction',
  'ledger.tx_editor.update': 'Update transaction',
  'ledger.tx_editor.created': 'Transaction created.',
  'ledger.tx_editor.updated': 'Transaction updated.',

  // LedgerOne – Transaction Types
  'ledger.tx_type.income': 'Income',
  'ledger.tx_type.expense': 'Expense',
  'ledger.tx_type.transfer': 'Transfer',
  'ledger.tx_type.trade': 'Trade',
  'ledger.tx_type.adjustment': 'Adjustment',

  // LedgerOne – Crypto Screen
  'ledger.crypto.title': 'Crypto assets',
  'ledger.crypto.by_asset': 'By asset',
  'ledger.crypto.by_account': 'By account',
  'ledger.crypto.no_assets':
      'No crypto assets yet. Add a crypto transaction to get started.',
  'ledger.crypto.no_accounts': 'No accounts yet. Create an account first.',
  'ledger.crypto.total_value': 'Total value',
  'ledger.crypto.assets': 'Assets',

  // LedgerOne – Money Screen
  'ledger.money.title': 'Money',
  'ledger.money.accounts': 'Accounts',
  'ledger.money.transactions': 'Transactions',
  'ledger.money.categories': 'Categories',
  'ledger.money.no_accounts': 'No accounts yet. Create one to get started.',
  'ledger.money.no_transactions': 'No transactions this month.',
  'ledger.money.this_month': 'This month',
  'ledger.money.total_income': 'Total income',
  'ledger.money.total_expenses': 'Total expenses',
  'ledger.money.net_income': 'Net income',

  // LedgerOne – Settings
  'ledger.settings.title': 'Settings',
  'ledger.settings.general': 'General',
  'ledger.settings.language': 'Language',
  'ledger.settings.theme': 'Theme',
  'ledger.settings.theme_light': 'Light',
  'ledger.settings.theme_dark': 'Dark',
  'ledger.settings.theme_system': 'System',
  'ledger.settings.data': 'Data',
  'ledger.settings.backup': 'Back up data',
  'ledger.settings.restore': 'Restore data',
  'ledger.settings.export': 'Export CSV',
  'ledger.settings.about': 'About',
  'ledger.settings.version': 'Version',

  // LedgerOne – Common
  'ledger.common.save': 'Save',
  'ledger.common.cancel': 'Cancel',
  'ledger.common.delete': 'Delete',
  'ledger.common.edit': 'Edit',
  'ledger.common.add': 'Add',
  'ledger.common.close': 'Close',
  'ledger.common.confirm': 'Confirm',
  'ledger.common.balance': 'Balance',
  'ledger.common.accounts': 'Accounts',
  'ledger.common.assets': 'Assets',
  'ledger.common.no_data': 'No data available',
  'ledger.common.loading': 'Loading...',
  'ledger.common.loading_data': 'Loading data...',

  // LedgerOne – Accessibility
  'ledger.a11y.update_prices': 'Update asset prices',
  'ledger.a11y.navigate_back': 'Navigate back',
  'ledger.a11y.open_settings': 'Open settings',
  'ledger.a11y.select_date': 'Select date',
  'ledger.a11y.select_time': 'Select time',
  'ledger.a11y.asset_icon': 'Asset icon for {asset}',
  'ledger.a11y.account_icon': 'Account icon for {account}',
};

/// German translations (de)
const Map<String, String> translationsDe = {
  // Common
  'app.name': 'LedgerOne',
  'common.ok': 'OK',
  'common.cancel': 'Abbrechen',
  'common.retry': 'Erneut versuchen',
  'common.loading': 'Wird geladen...',
  'common.error': 'Fehler',
  'common.success': 'Erfolg',

  // Onboarding
  'onboarding.title': 'Willkommen',
  'onboarding.subtitle':
      'Eine produktionsreife Flutter-Vorlage mit Navigation, Guards und sauberer Architektur.',
  'onboarding.get_started': 'Loslegen',
  'onboarding.skip': 'Überspringen',

  // Errors
  'error.network_offline':
      'Keine Internetverbindung. Bitte prüfe deine Netzwerkverbindung.',
  'error.timeout':
      'Zeitüberschreitung bei der Anfrage. Bitte versuche es erneut.',
  'error.server_error': 'Serverfehler. Bitte versuche es später erneut.',
  'error.bad_request': 'Ungültige Anfrage. Bitte überprüfe deine Eingaben.',
  'error.unauthorized':
      'Deine Sitzung ist abgelaufen. Bitte melde dich erneut an.',
  'error.forbidden': 'Du hast keine Berechtigung, diese Aktion auszuführen.',
  'error.not_found': 'Die angeforderte Ressource wurde nicht gefunden.',
  'error.invalid_credentials':
      'Ungültige E-Mail-Adresse oder ungültiges Passwort.',
  'error.session_expired':
      'Deine Sitzung ist abgelaufen. Bitte melde dich erneut an.',
  'error.parse_error':
      'Die Antwort konnte nicht verarbeitet werden. Bitte versuche es erneut.',
  'error.unknown': 'Etwas ist schiefgelaufen. Bitte versuche es erneut.',
  'error.inline_title': 'Etwas ist schiefgelaufen',

  // Accessibility labels
  'a11y.navigation.back': 'Zurück navigieren',
  'a11y.navigation.menu': 'Menü öffnen',
  'a11y.close_button': 'Schließen',
  'a11y.refresh_button': 'Inhalt aktualisieren',
  'a11y.loading_indicator': 'Wird geladen',
  'a11y.error_icon': 'Fehler',
  'a11y.success_icon': 'Erfolg',

  // Network status
  'network.offline': 'Keine Internetverbindung',
  'network.online': 'Verbunden',
  'network.unknown': 'Verbindungsstatus unbekannt',

  // ------------------------------------------------------------
  // LedgerOne – App & Onboarding
  // ------------------------------------------------------------
  'ledger.app_title': 'LedgerOne',

  // LedgerOne – Errors
  'ledger.error.stale_price':
      'Preisdaten sind veraltet. Aktualisiere die Kurse und versuche es erneut.',

  'ledger.onboarding.welcome_title': 'Willkommen bei LedgerOne',
  'ledger.onboarding.welcome_subtitle':
      'Dein privater Offline-Tracker für Finanzen und Krypto.',
  'ledger.onboarding.feature1_title': 'Alles im Blick',
  'ledger.onboarding.feature1_desc':
      'Verwalte Krypto und Fiat an einem Ort. Behalte alle Assets über alle Konten hinweg im Blick.',
  'ledger.onboarding.feature2_title': 'Offline-first',
  'ledger.onboarding.feature2_desc':
      'Funktioniert vollständig offline. Deine Daten bleiben auf deinem Gerät. Kurse werden nur aktualisiert, wenn du es möchtest.',
  'ledger.onboarding.feature3_title': 'Volle Kontrolle',
  'ledger.onboarding.feature3_desc':
      'Keine automatische Synchronisierung und keine versteckten Verbindungen. Du behältst die Kontrolle. Exportiere und sichere deine Daten jederzeit.',
  'ledger.onboarding.get_started': 'Loslegen',
  'ledger.onboarding.skip': 'Überspringen',
  'ledger.onboarding.next': 'Weiter',
  'ledger.onboarding.previous': 'Zurück',

  // LedgerOne – Dashboard
  'ledger.dashboard.title': 'Dashboard',
  'ledger.dashboard.total_portfolio': 'Gesamtportfolio',
  'ledger.dashboard.crypto': 'Krypto',
  'ledger.dashboard.fiat': 'Fiat',
  'ledger.dashboard.top_holdings': 'Top-Positionen',
  'ledger.dashboard.quick_actions': 'Schnellaktionen',
  'ledger.dashboard.no_assets':
      'Noch keine Assets erfasst. Lege deine erste Transaktion an.',
  'ledger.dashboard.update_prices': 'Kurse aktualisieren',
  'ledger.dashboard.updating_prices': 'Kurse werden aktualisiert...',
  'ledger.dashboard.prices_updated':
      '{success} Kurse aktualisiert, {failed} fehlgeschlagen.',
  'ledger.dashboard.price_update_failed':
      'Kurse konnten nicht aktualisiert werden.',
  'ledger.dashboard.last_update': 'Aktualisiert {time}',
  'ledger.dashboard.just_now': 'gerade eben',
  'ledger.dashboard.minutes_ago': 'vor {minutes} Min.',
  'ledger.dashboard.hours_ago': 'vor {hours} Std.',
  'ledger.dashboard.days_ago': 'vor {days} Tagen',

  // LedgerOne – Navigation
  'ledger.nav.dashboard': 'Dashboard',
  'ledger.nav.crypto': 'Krypto',
  'ledger.nav.money': 'Geld',
  'ledger.nav.settings': 'Einstellungen',

  // LedgerOne – Quick Actions
  'ledger.action.add_transaction': 'Transaktion hinzufügen',
  'ledger.action.view_accounts': 'Konten anzeigen',
  'ledger.action.manage_assets': 'Assets verwalten',
  'ledger.action.backup_data': 'Daten sichern',

  // LedgerOne – Transaction Editor
  'ledger.tx_editor.title': 'Neue Transaktion',
  'ledger.tx_editor.title_edit': 'Transaktion bearbeiten',
  'ledger.tx_editor.type': 'Transaktionstyp',
  'ledger.tx_editor.description': 'Beschreibung',
  'ledger.tx_editor.description_hint':
      'Kurze Beschreibung der Transaktion eingeben',
  'ledger.tx_editor.description_required': 'Beschreibung ist erforderlich',
  'ledger.tx_editor.date_time': 'Datum & Uhrzeit',
  'ledger.tx_editor.account': 'Konto',
  'ledger.tx_editor.account_required': 'Konto ist erforderlich',
  'ledger.tx_editor.from_account': 'Quellkonto',
  'ledger.tx_editor.to_account': 'Zielkonto',
  'ledger.tx_editor.to_account_required': 'Zielkonto ist erforderlich',
  'ledger.tx_editor.asset': 'Asset',
  'ledger.tx_editor.asset_required': 'Asset ist erforderlich',
  'ledger.tx_editor.from_asset': 'Quell-Asset (Zahlung)',
  'ledger.tx_editor.from_asset_required': 'Quell-Asset ist erforderlich',
  'ledger.tx_editor.to_asset': 'Ziel-Asset (Empfang)',
  'ledger.tx_editor.to_asset_required': 'Ziel-Asset ist erforderlich',
  'ledger.tx_editor.fee_asset': 'Gebühren-Asset (optional)',
  'ledger.tx_editor.fee_asset_hint':
      'Auswählen, falls eine Gebühr angefallen ist',
  'ledger.tx_editor.no_fee': 'Keine Gebühr',
  'ledger.tx_editor.amount': 'Betrag',
  'ledger.tx_editor.amount_required': 'Betrag ist erforderlich',
  'ledger.tx_editor.amount_invalid': 'Bitte einen gültigen Betrag eingeben',
  'ledger.tx_editor.amount_paid': 'Gezahlter Betrag',
  'ledger.tx_editor.amount_received': 'Erhaltener Betrag',
  'ledger.tx_editor.fee_amount': 'Gebührenbetrag',
  'ledger.tx_editor.category': 'Kategorie',
  'ledger.tx_editor.category_required':
      'Für Ausgaben ist eine Kategorie erforderlich',
  'ledger.tx_editor.adjustment_helper':
      'Positive Werte erhöhen den Saldo, negative verringern ihn.',
  'ledger.tx_editor.create': 'Transaktion erstellen',
  'ledger.tx_editor.update': 'Transaktion aktualisieren',
  'ledger.tx_editor.created': 'Transaktion erstellt.',
  'ledger.tx_editor.updated': 'Transaktion aktualisiert.',

  // LedgerOne – Transaction Types
  'ledger.tx_type.income': 'Einnahme',
  'ledger.tx_type.expense': 'Ausgabe',
  'ledger.tx_type.transfer': 'Überweisung',
  'ledger.tx_type.trade': 'Handel',
  'ledger.tx_type.adjustment': 'Anpassung',

  // LedgerOne – Crypto Screen
  'ledger.crypto.title': 'Krypto-Assets',
  'ledger.crypto.by_asset': 'Nach Asset',
  'ledger.crypto.by_account': 'Nach Konto',
  'ledger.crypto.no_assets':
      'Noch keine Krypto-Assets erfasst. Lege eine Transaktion an.',
  'ledger.crypto.no_accounts': 'Noch keine Konten. Erstelle zuerst ein Konto.',
  'ledger.crypto.total_value': 'Gesamtwert',
  'ledger.crypto.assets': 'Assets',

  // LedgerOne – Money Screen
  'ledger.money.title': 'Geld',
  'ledger.money.accounts': 'Konten',
  'ledger.money.transactions': 'Transaktionen',
  'ledger.money.categories': 'Kategorien',
  'ledger.money.no_accounts':
      'Noch keine Konten vorhanden. Erstelle ein Konto, um zu starten.',
  'ledger.money.no_transactions': 'Keine Transaktionen in diesem Monat.',
  'ledger.money.this_month': 'Dieser Monat',
  'ledger.money.total_income': 'Gesamteinnahmen',
  'ledger.money.total_expenses': 'Gesamtausgaben',
  'ledger.money.net_income': 'Nettoeinkommen',

  // LedgerOne – Settings
  'ledger.settings.title': 'Einstellungen',
  'ledger.settings.general': 'Allgemein',
  'ledger.settings.language': 'Sprache',
  'ledger.settings.theme': 'Design',
  'ledger.settings.theme_light': 'Hell',
  'ledger.settings.theme_dark': 'Dunkel',
  'ledger.settings.theme_system': 'System',
  'ledger.settings.data': 'Daten',
  'ledger.settings.backup': 'Daten sichern',
  'ledger.settings.restore': 'Daten wiederherstellen',
  'ledger.settings.export': 'CSV exportieren',
  'ledger.settings.about': 'Über',
  'ledger.settings.version': 'Version',

  // LedgerOne – Common
  'ledger.common.save': 'Speichern',
  'ledger.common.cancel': 'Abbrechen',
  'ledger.common.delete': 'Löschen',
  'ledger.common.edit': 'Bearbeiten',
  'ledger.common.add': 'Hinzufügen',
  'ledger.common.close': 'Schließen',
  'ledger.common.confirm': 'Bestätigen',
  'ledger.common.balance': 'Saldo',
  'ledger.common.accounts': 'Konten',
  'ledger.common.assets': 'Assets',
  'ledger.common.no_data': 'Keine Daten verfügbar',
  'ledger.common.loading': 'Wird geladen...',
  'ledger.common.loading_data': 'Daten werden geladen...',

  // LedgerOne – Accessibility
  'ledger.a11y.update_prices': 'Asset-Kurse aktualisieren',
  'ledger.a11y.navigate_back': 'Zurück navigieren',
  'ledger.a11y.open_settings': 'Einstellungen öffnen',
  'ledger.a11y.select_date': 'Datum auswählen',
  'ledger.a11y.select_time': 'Uhrzeit auswählen',
  'ledger.a11y.asset_icon': 'Asset-Symbol für {asset}',
  'ledger.a11y.account_icon': 'Konto-Symbol für {account}',
};

/// Persian (Farsi) translations (fa) - RTL language
const Map<String, String> translationsFa = {
  // Common
  'app.name': 'لجر وان',
  'common.ok': 'تأیید',
  'common.cancel': 'انصراف',
  'common.retry': 'تلاش دوباره',
  'common.loading': 'در حال بارگذاری...',
  'common.error': 'خطا',
  'common.success': 'موفقیت',

  // Onboarding
  'onboarding.title': 'خوش آمدید',
  'onboarding.subtitle':
      'یک قالب آماده برای محیط واقعی با ناوبری، گاردها و معماری تمیز.',
  'onboarding.get_started': 'شروع کنید',
  'onboarding.skip': 'رد کردن',

  // Errors
  'error.network_offline':
      'هیچ اتصال اینترنتی وجود ندارد. لطفاً شبکه خود را بررسی کنید.',
  'error.timeout': 'مهلت درخواست به پایان رسید. لطفاً دوباره تلاش کنید.',
  'error.server_error': 'خطای سرور رخ داد. لطفاً بعداً دوباره تلاش کنید.',
  'error.bad_request': 'درخواست نامعتبر است. لطفاً ورودی خود را بررسی کنید.',
  'error.unauthorized': 'نشست شما منقضی شده است. لطفاً دوباره وارد شوید.',
  'error.forbidden': 'شما مجوز انجام این کار را ندارید.',
  'error.not_found': 'منبع درخواستی یافت نشد.',
  'error.invalid_credentials': 'ایمیل یا رمز عبور نادرست است.',
  'error.session_expired': 'نشست شما منقضی شده است. لطفاً دوباره وارد شوید.',
  'error.parse_error': 'امکان پردازش پاسخ وجود ندارد. لطفاً دوباره تلاش کنید.',
  'error.unknown': 'مشکلی پیش آمد. لطفاً دوباره تلاش کنید.',
  'error.inline_title': 'مشکلی پیش آمد',

  // Accessibility labels
  'a11y.navigation.back': 'بازگشت',
  'a11y.navigation.menu': 'باز کردن منو',
  'a11y.close_button': 'بستن',
  'a11y.refresh_button': 'به‌روزرسانی محتوا',
  'a11y.loading_indicator': 'در حال بارگذاری',
  'a11y.error_icon': 'خطا',
  'a11y.success_icon': 'موفقیت',

  // Network status
  'network.offline': 'بدون اتصال اینترنت',
  'network.online': 'متصل',
  'network.unknown': 'وضعیت اتصال نامشخص است',

  // ------------------------------------------------------------
  // LedgerOne – App & Onboarding
  // ------------------------------------------------------------
  'ledger.app_title': 'LedgerOne',

  // LedgerOne – Errors
  'ledger.error.stale_price':
      'اطلاعات قیمت قدیمی است. قیمت‌ها را به‌روزرسانی کنید و دوباره تلاش کنید.',

  'ledger.onboarding.welcome_title': 'به LedgerOne خوش آمدید',
  'ledger.onboarding.welcome_subtitle':
      'ردیاب شخصی، آفلاین و امن برای دارایی‌های مالی و کریپتوی شما.',
  'ledger.onboarding.feature1_title': 'پیگیری همه چیز',
  'ledger.onboarding.feature1_desc':
      'کریپتو و پول نقد را یک‌جا مدیریت کنید. همه دارایی‌های خود را در تمام حساب‌ها ببینید.',
  'ledger.onboarding.feature2_title': 'اول آفلاین',
  'ledger.onboarding.feature2_desc':
      'کاملاً آفلاین کار می‌کند. داده‌های شما فقط روی دستگاه شما می‌ماند. قیمت‌ها فقط زمانی که خودتان بخواهید به‌روزرسانی می‌شوند.',
  'ledger.onboarding.feature3_title': 'کنترل کامل',
  'ledger.onboarding.feature3_desc':
      'بدون همگام‌سازی خودکار و بدون اتصال پنهان. همه چیز تحت کنترل شماست. هر زمان خواستید می‌توانید خروجی بگیرید و پشتیبان تهیه کنید.',
  'ledger.onboarding.get_started': 'شروع کنید',
  'ledger.onboarding.skip': 'رد کردن',
  'ledger.onboarding.next': 'بعدی',
  'ledger.onboarding.previous': 'قبلی',

  // LedgerOne – Dashboard
  'ledger.dashboard.title': 'داشبورد',
  'ledger.dashboard.total_portfolio': 'ارزش کل پرتفوی',
  'ledger.dashboard.crypto': 'کریپتو',
  'ledger.dashboard.fiat': 'فیات',
  'ledger.dashboard.top_holdings': 'دارایی‌های برتر',
  'ledger.dashboard.quick_actions': 'اقدامات سریع',
  'ledger.dashboard.no_assets':
      'هنوز هیچ دارایی‌ای ثبت نکرده‌اید. اولین تراکنش خود را اضافه کنید.',
  'ledger.dashboard.update_prices': 'به‌روزرسانی قیمت‌ها',
  'ledger.dashboard.updating_prices': 'در حال به‌روزرسانی قیمت‌ها...',
  'ledger.dashboard.prices_updated':
      '{success} قیمت به‌روزرسانی شد؛ {failed} مورد ناموفق بود.',
  'ledger.dashboard.price_update_failed': 'به‌روزرسانی قیمت‌ها ناموفق بود.',
  'ledger.dashboard.last_update': 'آخرین به‌روزرسانی: {time}',
  'ledger.dashboard.just_now': 'همین الان',
  'ledger.dashboard.minutes_ago': '{minutes} دقیقه پیش',
  'ledger.dashboard.hours_ago': '{hours} ساعت پیش',
  'ledger.dashboard.days_ago': '{days} روز پیش',

  // LedgerOne – Navigation
  'ledger.nav.dashboard': 'داشبورد',
  'ledger.nav.crypto': 'کریپتو',
  'ledger.nav.money': 'پول',
  'ledger.nav.settings': 'تنظیمات',

  // LedgerOne – Quick Actions
  'ledger.action.add_transaction': 'افزودن تراکنش',
  'ledger.action.view_accounts': 'مشاهده حساب‌ها',
  'ledger.action.manage_assets': 'مدیریت دارایی‌ها',
  'ledger.action.backup_data': 'پشتیبان‌گیری از داده‌ها',

  // LedgerOne – Transaction Editor
  'ledger.tx_editor.title': 'تراکنش جدید',
  'ledger.tx_editor.title_edit': 'ویرایش تراکنش',
  'ledger.tx_editor.type': 'نوع تراکنش',
  'ledger.tx_editor.description': 'توضیحات',
  'ledger.tx_editor.description_hint':
      'یک توضیح کوتاه برای این تراکنش وارد کنید',
  'ledger.tx_editor.description_required': 'توضیحات الزامی است',
  'ledger.tx_editor.date_time': 'تاریخ و زمان',
  'ledger.tx_editor.account': 'حساب',
  'ledger.tx_editor.account_required': 'انتخاب حساب الزامی است',
  'ledger.tx_editor.from_account': 'از حساب',
  'ledger.tx_editor.to_account': 'به حساب',
  'ledger.tx_editor.to_account_required': 'حساب مقصد الزامی است',
  'ledger.tx_editor.asset': 'دارایی',
  'ledger.tx_editor.asset_required': 'انتخاب دارایی الزامی است',
  'ledger.tx_editor.from_asset': 'از دارایی (پرداخت)',
  'ledger.tx_editor.from_asset_required': 'دارایی مبدأ الزامی است',
  'ledger.tx_editor.to_asset': 'به دارایی (دریافت)',
  'ledger.tx_editor.to_asset_required': 'دارایی مقصد الزامی است',
  'ledger.tx_editor.fee_asset': 'دارایی کارمزد (اختیاری)',
  'ledger.tx_editor.fee_asset_hint':
      'اگر کارمزدی پرداخت شده، دارایی کارمزد را انتخاب کنید',
  'ledger.tx_editor.no_fee': 'بدون کارمزد',
  'ledger.tx_editor.amount': 'مقدار',
  'ledger.tx_editor.amount_required': 'مقدار الزامی است',
  'ledger.tx_editor.amount_invalid': 'یک مقدار معتبر وارد کنید',
  'ledger.tx_editor.amount_paid': 'مقدار پرداخت‌شده',
  'ledger.tx_editor.amount_received': 'مقدار دریافت‌شده',
  'ledger.tx_editor.fee_amount': 'مقدار کارمزد',
  'ledger.tx_editor.category': 'دسته',
  'ledger.tx_editor.category_required': 'برای هزینه‌ها انتخاب دسته الزامی است',
  'ledger.tx_editor.adjustment_helper':
      'مقادیر مثبت موجودی را افزایش می‌دهند و مقادیر منفی آن را کاهش می‌دهند.',
  'ledger.tx_editor.create': 'ایجاد تراکنش',
  'ledger.tx_editor.update': 'به‌روزرسانی تراکنش',
  'ledger.tx_editor.created': 'تراکنش ایجاد شد.',
  'ledger.tx_editor.updated': 'تراکنش به‌روزرسانی شد.',

  // LedgerOne – Transaction Types
  'ledger.tx_type.income': 'درآمد',
  'ledger.tx_type.expense': 'هزینه',
  'ledger.tx_type.transfer': 'انتقال',
  'ledger.tx_type.trade': 'معامله',
  'ledger.tx_type.adjustment': 'تنظیم',

  // LedgerOne – Crypto Screen
  'ledger.crypto.title': 'دارایی‌های کریپتو',
  'ledger.crypto.by_asset': 'بر اساس دارایی',
  'ledger.crypto.by_account': 'بر اساس حساب',
  'ledger.crypto.no_assets':
      'هنوز هیچ دارایی کریپتویی ثبت نکرده‌اید. یک تراکنش اضافه کنید.',
  'ledger.crypto.no_accounts': 'هنوز حسابی ندارید. ابتدا یک حساب ایجاد کنید.',
  'ledger.crypto.total_value': 'ارزش کل',
  'ledger.crypto.assets': 'دارایی‌ها',

  // LedgerOne – Money Screen
  'ledger.money.title': 'پول',
  'ledger.money.accounts': 'حساب‌ها',
  'ledger.money.transactions': 'تراکنش‌ها',
  'ledger.money.categories': 'دسته‌ها',
  'ledger.money.no_accounts':
      'هنوز هیچ حسابی ثبت نشده است. یک حساب جدید ایجاد کنید.',
  'ledger.money.no_transactions': 'در این ماه تراکنشی ثبت نشده است.',
  'ledger.money.this_month': 'این ماه',
  'ledger.money.total_income': 'کل درآمد',
  'ledger.money.total_expenses': 'کل هزینه‌ها',
  'ledger.money.net_income': 'درآمد خالص',

  // LedgerOne – Settings
  'ledger.settings.title': 'تنظیمات',
  'ledger.settings.general': 'عمومی',
  'ledger.settings.language': 'زبان',
  'ledger.settings.theme': 'تم',
  'ledger.settings.theme_light': 'روشن',
  'ledger.settings.theme_dark': 'تیره',
  'ledger.settings.theme_system': 'سیستم',
  'ledger.settings.data': 'داده‌ها',
  'ledger.settings.backup': 'پشتیبان‌گیری از داده‌ها',
  'ledger.settings.restore': 'بازیابی داده‌ها',
  'ledger.settings.export': 'خروجی CSV',
  'ledger.settings.about': 'درباره',
  'ledger.settings.version': 'نسخه',

  // LedgerOne – Common
  'ledger.common.save': 'ذخیره',
  'ledger.common.cancel': 'لغو',
  'ledger.common.delete': 'حذف',
  'ledger.common.edit': 'ویرایش',
  'ledger.common.add': 'افزودن',
  'ledger.common.close': 'بستن',
  'ledger.common.confirm': 'تأیید',
  'ledger.common.balance': 'موجودی',
  'ledger.common.accounts': 'حساب‌ها',
  'ledger.common.assets': 'دارایی‌ها',
  'ledger.common.no_data': 'هیچ داده‌ای موجود نیست',
  'ledger.common.loading': 'در حال بارگذاری...',
  'ledger.common.loading_data': 'در حال بارگذاری داده‌ها...',

  // LedgerOne – Accessibility
  'ledger.a11y.update_prices': 'به‌روزرسانی قیمت دارایی‌ها',
  'ledger.a11y.navigate_back': 'بازگشت',
  'ledger.a11y.open_settings': 'باز کردن تنظیمات',
  'ledger.a11y.select_date': 'انتخاب تاریخ',
  'ledger.a11y.select_time': 'انتخاب زمان',
  'ledger.a11y.asset_icon': 'نماد دارایی برای {asset}',
  'ledger.a11y.account_icon': 'نماد حساب برای {account}',
};

const Map<String, Map<String, String>> allTranslations = {
  'en': translationsEn,
  'de': translationsDe,
  'fa': translationsFa,
};
