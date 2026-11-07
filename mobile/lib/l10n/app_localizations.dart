import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ta.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ta')
  ];

  /// The name of the application
  ///
  /// In en, this message translates to:
  /// **'ZOLO ERP'**
  String get appName;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navTasks.
  ///
  /// In en, this message translates to:
  /// **'My Tasks'**
  String get navTasks;

  /// No description provided for @navNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get navNew;

  /// No description provided for @navModules.
  ///
  /// In en, this message translates to:
  /// **'Modules'**
  String get navModules;

  /// No description provided for @navMe.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navMe;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @scanBarcode.
  ///
  /// In en, this message translates to:
  /// **'Scan Barcode'**
  String get scanBarcode;

  /// No description provided for @statusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get statusDraft;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @statusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get statusApproved;

  /// No description provided for @statusPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get statusPaid;

  /// No description provided for @statusOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get statusOverdue;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @statusSynced.
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get statusSynced;

  /// No description provided for @statusSyncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing'**
  String get statusSyncing;

  /// No description provided for @statusOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline Mode'**
  String get statusOffline;

  /// No description provided for @liveData.
  ///
  /// In en, this message translates to:
  /// **'Live Server'**
  String get liveData;

  /// No description provided for @cachedData.
  ///
  /// In en, this message translates to:
  /// **'Cached Snapshot'**
  String get cachedData;

  /// No description provided for @switchCompany.
  ///
  /// In en, this message translates to:
  /// **'Switch Company'**
  String get switchCompany;

  /// No description provided for @activeCompany.
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get activeCompany;

  /// No description provided for @activeBranch.
  ///
  /// In en, this message translates to:
  /// **'Branch'**
  String get activeBranch;

  /// No description provided for @activeFinancialYear.
  ///
  /// In en, this message translates to:
  /// **'Financial Year'**
  String get activeFinancialYear;

  /// No description provided for @newSaleBill.
  ///
  /// In en, this message translates to:
  /// **'New Sale Bill'**
  String get newSaleBill;

  /// No description provided for @collectPayment.
  ///
  /// In en, this message translates to:
  /// **'Collect Payment'**
  String get collectPayment;

  /// No description provided for @newCustomer.
  ///
  /// In en, this message translates to:
  /// **'New Customer (KYC)'**
  String get newCustomer;

  /// No description provided for @addExpense.
  ///
  /// In en, this message translates to:
  /// **'Quick Expense'**
  String get addExpense;

  /// No description provided for @newPurchaseBill.
  ///
  /// In en, this message translates to:
  /// **'Purchase Bill'**
  String get newPurchaseBill;

  /// No description provided for @stockCount.
  ///
  /// In en, this message translates to:
  /// **'Physical Stock Count'**
  String get stockCount;

  /// No description provided for @markAttendance.
  ///
  /// In en, this message translates to:
  /// **'Mark Attendance'**
  String get markAttendance;

  /// No description provided for @ticketSale.
  ///
  /// In en, this message translates to:
  /// **'Water Can Sale'**
  String get ticketSale;

  /// No description provided for @tankerTrip.
  ///
  /// In en, this message translates to:
  /// **'Tanker Trip Sheet'**
  String get tankerTrip;

  /// No description provided for @cashBalance.
  ///
  /// In en, this message translates to:
  /// **'Cash Balance'**
  String get cashBalance;

  /// No description provided for @bankBalance.
  ///
  /// In en, this message translates to:
  /// **'Bank Balance'**
  String get bankBalance;

  /// No description provided for @receivables.
  ///
  /// In en, this message translates to:
  /// **'Receivables'**
  String get receivables;

  /// No description provided for @payables.
  ///
  /// In en, this message translates to:
  /// **'Payables'**
  String get payables;

  /// No description provided for @salesToday.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Sales'**
  String get salesToday;

  /// No description provided for @collectionsToday.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Collections'**
  String get collectionsToday;

  /// No description provided for @stockValuation.
  ///
  /// In en, this message translates to:
  /// **'Stock Valuation'**
  String get stockValuation;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign In to ERP'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your corporate credentials'**
  String get loginSubtitle;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username / Phone'**
  String get username;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @signingIn.
  ///
  /// In en, this message translates to:
  /// **'Authenticating...'**
  String get signingIn;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get logout;

  /// No description provided for @invalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid username or password'**
  String get invalidCredentials;

  /// No description provided for @categorySell.
  ///
  /// In en, this message translates to:
  /// **'Sales & Commercial'**
  String get categorySell;

  /// No description provided for @categoryBuy.
  ///
  /// In en, this message translates to:
  /// **'Procurement & Purchases'**
  String get categoryBuy;

  /// No description provided for @categoryStock.
  ///
  /// In en, this message translates to:
  /// **'Inventory & Godowns'**
  String get categoryStock;

  /// No description provided for @categoryParties.
  ///
  /// In en, this message translates to:
  /// **'Customers & Suppliers'**
  String get categoryParties;

  /// No description provided for @categoryFinance.
  ///
  /// In en, this message translates to:
  /// **'Accounting & Cash Books'**
  String get categoryFinance;

  /// No description provided for @categoryOperations.
  ///
  /// In en, this message translates to:
  /// **'Vertical Operations'**
  String get categoryOperations;

  /// No description provided for @categoryPeople.
  ///
  /// In en, this message translates to:
  /// **'HRM & Attendance'**
  String get categoryPeople;

  /// No description provided for @categoryReports.
  ///
  /// In en, this message translates to:
  /// **'Analytics & Reports'**
  String get categoryReports;

  /// No description provided for @categoryAdmin.
  ///
  /// In en, this message translates to:
  /// **'Administration'**
  String get categoryAdmin;

  /// No description provided for @canSalesPos.
  ///
  /// In en, this message translates to:
  /// **'Can Sales POS'**
  String get canSalesPos;

  /// No description provided for @plantRefill.
  ///
  /// In en, this message translates to:
  /// **'Plant Refill Manifest'**
  String get plantRefill;

  /// No description provided for @tankerDelivery.
  ///
  /// In en, this message translates to:
  /// **'Tanker Delivery'**
  String get tankerDelivery;

  /// No description provided for @spotAudit.
  ///
  /// In en, this message translates to:
  /// **'Spot Empty Can Audit'**
  String get spotAudit;

  /// No description provided for @driverSurrender.
  ///
  /// In en, this message translates to:
  /// **'Driver Cash Surrender'**
  String get driverSurrender;

  /// No description provided for @cafePos.
  ///
  /// In en, this message translates to:
  /// **'Cafe & Bakery POS'**
  String get cafePos;

  /// No description provided for @drawerReconcile.
  ///
  /// In en, this message translates to:
  /// **'Cash Drawer Reconcile'**
  String get drawerReconcile;

  /// No description provided for @syncCentre.
  ///
  /// In en, this message translates to:
  /// **'Sync Centre'**
  String get syncCentre;

  /// No description provided for @syncPending.
  ///
  /// In en, this message translates to:
  /// **'Pending Records'**
  String get syncPending;

  /// No description provided for @syncAllNow.
  ///
  /// In en, this message translates to:
  /// **'Sync All Now'**
  String get syncAllNow;

  /// No description provided for @emptyStateMessage.
  ///
  /// In en, this message translates to:
  /// **'No records found'**
  String get emptyStateMessage;

  /// No description provided for @errorStateMessage.
  ///
  /// In en, this message translates to:
  /// **'Unable to load data from server'**
  String get errorStateMessage;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ta'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ta':
      return AppLocalizationsTa();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
