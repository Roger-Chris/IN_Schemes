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
    Locale('ta'),
  ];

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning,'**
  String get goodMorning;

  /// No description provided for @completeYourProfile.
  ///
  /// In en, this message translates to:
  /// **'Complete Your Profile'**
  String get completeYourProfile;

  /// No description provided for @unlockPersonalizedSchemeRecommendations.
  ///
  /// In en, this message translates to:
  /// **'Unlock personalized scheme recommendations.'**
  String get unlockPersonalizedSchemeRecommendations;

  /// No description provided for @applicationsClosingSoon.
  ///
  /// In en, this message translates to:
  /// **'Applications Closing Soon'**
  String get applicationsClosingSoon;

  /// No description provided for @featured.
  ///
  /// In en, this message translates to:
  /// **'Featured'**
  String get featured;

  /// No description provided for @forWomenEntrepreneurs.
  ///
  /// In en, this message translates to:
  /// **'For Women Entrepreneurs'**
  String get forWomenEntrepreneurs;

  /// No description provided for @exploreSpecialFundingSchemes.
  ///
  /// In en, this message translates to:
  /// **'Explore special funding schemes'**
  String get exploreSpecialFundingSchemes;

  /// No description provided for @whatWouldYouLikeToDoToday.
  ///
  /// In en, this message translates to:
  /// **'What would you like to do today?'**
  String get whatWouldYouLikeToDoToday;

  /// No description provided for @exportSupport.
  ///
  /// In en, this message translates to:
  /// **'Export Support'**
  String get exportSupport;

  /// No description provided for @growBusiness.
  ///
  /// In en, this message translates to:
  /// **'Grow Business'**
  String get growBusiness;

  /// No description provided for @registerUdyam.
  ///
  /// In en, this message translates to:
  /// **'Register UDYAM'**
  String get registerUdyam;

  /// No description provided for @findFunding.
  ///
  /// In en, this message translates to:
  /// **'Find Funding'**
  String get findFunding;

  /// No description provided for @startABusiness.
  ///
  /// In en, this message translates to:
  /// **'Start a Business'**
  String get startABusiness;

  /// No description provided for @exploreMsmeSupport.
  ///
  /// In en, this message translates to:
  /// **'Explore MSME Support'**
  String get exploreMsmeSupport;

  /// No description provided for @schemes.
  ///
  /// In en, this message translates to:
  /// **'Schemes'**
  String get schemes;

  /// No description provided for @finance.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get finance;

  /// No description provided for @taxGst.
  ///
  /// In en, this message translates to:
  /// **'Tax & GST'**
  String get taxGst;

  /// No description provided for @export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// No description provided for @treds.
  ///
  /// In en, this message translates to:
  /// **'TReDS'**
  String get treds;

  /// No description provided for @csrSupport.
  ///
  /// In en, this message translates to:
  /// **'CSR Support'**
  String get csrSupport;

  /// No description provided for @govtAuthorities.
  ///
  /// In en, this message translates to:
  /// **'Govt. Authorities'**
  String get govtAuthorities;

  /// No description provided for @institutions.
  ///
  /// In en, this message translates to:
  /// **'Institutions'**
  String get institutions;

  /// No description provided for @recommendedForYou.
  ///
  /// In en, this message translates to:
  /// **'Recommended For You'**
  String get recommendedForYou;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @latestUpdates.
  ///
  /// In en, this message translates to:
  /// **'Latest Updates'**
  String get latestUpdates;

  /// No description provided for @tipOfTheDay.
  ///
  /// In en, this message translates to:
  /// **'Tip of the Day'**
  String get tipOfTheDay;

  /// No description provided for @askAi.
  ///
  /// In en, this message translates to:
  /// **'Ask AI'**
  String get askAi;

  /// No description provided for @searchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search schemes, benefits or ask anything...'**
  String get searchPlaceholder;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get navSearch;

  /// No description provided for @navDiscover.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get navDiscover;

  /// No description provided for @navSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get navSaved;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @quickPillPmegp.
  ///
  /// In en, this message translates to:
  /// **'Search PMEGP'**
  String get quickPillPmegp;

  /// No description provided for @quickPillStartup.
  ///
  /// In en, this message translates to:
  /// **'Search Startup India'**
  String get quickPillStartup;

  /// No description provided for @quickPillLoans.
  ///
  /// In en, this message translates to:
  /// **'Search MSME Loans'**
  String get quickPillLoans;

  /// No description provided for @quickPillWomen.
  ///
  /// In en, this message translates to:
  /// **'Search Women Entrepreneur Schemes'**
  String get quickPillWomen;

  /// No description provided for @quickPillAscend.
  ///
  /// In en, this message translates to:
  /// **'Search ASCEND Workshops'**
  String get quickPillAscend;

  /// No description provided for @carouselTitleApplicationsClosingSoon.
  ///
  /// In en, this message translates to:
  /// **'Applications Closing Soon'**
  String get carouselTitleApplicationsClosingSoon;

  /// No description provided for @carouselSubPmegpDaysLeft.
  ///
  /// In en, this message translates to:
  /// **'PMEGP · 2 days left'**
  String get carouselSubPmegpDaysLeft;

  /// No description provided for @carouselBadgeAlert.
  ///
  /// In en, this message translates to:
  /// **'Alert'**
  String get carouselBadgeAlert;

  /// No description provided for @carouselTitleNewScheme.
  ///
  /// In en, this message translates to:
  /// **'New Scheme'**
  String get carouselTitleNewScheme;

  /// No description provided for @carouselSubTnExport.
  ///
  /// In en, this message translates to:
  /// **'TN Export Promotion Scheme'**
  String get carouselSubTnExport;

  /// No description provided for @carouselBadgeNewScheme.
  ///
  /// In en, this message translates to:
  /// **'New Scheme'**
  String get carouselBadgeNewScheme;

  /// No description provided for @carouselTitleImportantUpdate.
  ///
  /// In en, this message translates to:
  /// **'Important Update'**
  String get carouselTitleImportantUpdate;

  /// No description provided for @carouselSubUdyamProcess.
  ///
  /// In en, this message translates to:
  /// **'UDYAM registration process updated'**
  String get carouselSubUdyamProcess;

  /// No description provided for @carouselBadgeNotify.
  ///
  /// In en, this message translates to:
  /// **'Notify'**
  String get carouselBadgeNotify;

  /// No description provided for @subsidiesGrantsGovtSchemes.
  ///
  /// In en, this message translates to:
  /// **'Subsidies, grants & government schemes'**
  String get subsidiesGrantsGovtSchemes;

  /// No description provided for @loansCreditSupportFundingOptions.
  ///
  /// In en, this message translates to:
  /// **'Loans, credit support & funding options'**
  String get loansCreditSupportFundingOptions;

  /// No description provided for @taxBenefitsGstSupportCompliance.
  ///
  /// In en, this message translates to:
  /// **'Tax benefits, GST support & compliance'**
  String get taxBenefitsGstSupportCompliance;

  /// No description provided for @exportIncentivesFinanceMarketSupport.
  ///
  /// In en, this message translates to:
  /// **'Export incentives, finance & market support'**
  String get exportIncentivesFinanceMarketSupport;

  /// No description provided for @invoiceDiscountingWorkingCapital.
  ///
  /// In en, this message translates to:
  /// **'Invoice discounting & working capital solutions'**
  String get invoiceDiscountingWorkingCapital;

  /// No description provided for @csrProgramsIncubatorsClusterSupport.
  ///
  /// In en, this message translates to:
  /// **'CSR programs, incubators & cluster support'**
  String get csrProgramsIncubatorsClusterSupport;

  /// No description provided for @centralStateDistrictGovtStructure.
  ///
  /// In en, this message translates to:
  /// **'Central, State & District government structure'**
  String get centralStateDistrictGovtStructure;

  /// No description provided for @sidbiNsicDicKvicMoreOrganizations.
  ///
  /// In en, this message translates to:
  /// **'SIDBI, NSIC, DIC, KVIC & more organizations'**
  String get sidbiNsicDicKvicMoreOrganizations;

  /// No description provided for @tipOfTheDayContent.
  ///
  /// In en, this message translates to:
  /// **'Women Entrepreneurs may receive additional subsidy under PMEGP.'**
  String get tipOfTheDayContent;

  /// No description provided for @tagNewScheme.
  ///
  /// In en, this message translates to:
  /// **'New Scheme'**
  String get tagNewScheme;

  /// No description provided for @tagUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get tagUpdate;

  /// No description provided for @tagReminder.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get tagReminder;

  /// No description provided for @tagAlert.
  ///
  /// In en, this message translates to:
  /// **'Alert'**
  String get tagAlert;

  /// No description provided for @fallbackLatestUpdateTitle.
  ///
  /// In en, this message translates to:
  /// **'Fisheries and Aquaculture Infra Development Fund Scheme Launched'**
  String get fallbackLatestUpdateTitle;

  /// No description provided for @time2DaysAgo.
  ///
  /// In en, this message translates to:
  /// **'2 days ago'**
  String get time2DaysAgo;

  /// No description provided for @searchTitle.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchTitle;

  /// No description provided for @trySearchPrefix.
  ///
  /// In en, this message translates to:
  /// **'Try:'**
  String get trySearchPrefix;

  /// No description provided for @quickFiltersHeader.
  ///
  /// In en, this message translates to:
  /// **'Quick Filters'**
  String get quickFiltersHeader;

  /// No description provided for @sortByPrefix.
  ///
  /// In en, this message translates to:
  /// **'Sort by:'**
  String get sortByPrefix;

  /// No description provided for @sortMatchPercent.
  ///
  /// In en, this message translates to:
  /// **'Match %'**
  String get sortMatchPercent;

  /// No description provided for @sortNameAsc.
  ///
  /// In en, this message translates to:
  /// **'Scheme Name (A-Z)'**
  String get sortNameAsc;

  /// No description provided for @sortNameDesc.
  ///
  /// In en, this message translates to:
  /// **'Scheme Name (Z-A)'**
  String get sortNameDesc;

  /// No description provided for @browseCategories.
  ///
  /// In en, this message translates to:
  /// **'Browse Categories'**
  String get browseCategories;

  /// No description provided for @forMe.
  ///
  /// In en, this message translates to:
  /// **'For Me'**
  String get forMe;

  /// No description provided for @activeBadge.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeBadge;

  /// No description provided for @calculatingMatches.
  ///
  /// In en, this message translates to:
  /// **'Calculating matches...'**
  String get calculatingMatches;

  /// No description provided for @schemesMatchProfile.
  ///
  /// In en, this message translates to:
  /// **'{count} schemes match your profile.'**
  String schemesMatchProfile(Object count);

  /// No description provided for @noSchemesFound.
  ///
  /// In en, this message translates to:
  /// **'No schemes found for \"{query}\"'**
  String noSchemesFound(Object query);

  /// No description provided for @tryDifferentKeyword.
  ///
  /// In en, this message translates to:
  /// **'Try a different keyword or browse categories.'**
  String get tryDifferentKeyword;

  /// No description provided for @resultsFor.
  ///
  /// In en, this message translates to:
  /// **'{count} results for \"{query}\"'**
  String resultsFor(Object count, Object query);

  /// No description provided for @matchScorePercent.
  ///
  /// In en, this message translates to:
  /// **'{percent}% Match'**
  String matchScorePercent(Object percent);

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterCentral.
  ///
  /// In en, this message translates to:
  /// **'Central'**
  String get filterCentral;

  /// No description provided for @filterState.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get filterState;

  /// No description provided for @filterLoan.
  ///
  /// In en, this message translates to:
  /// **'Loan'**
  String get filterLoan;

  /// No description provided for @filterUdyam.
  ///
  /// In en, this message translates to:
  /// **'Udyam'**
  String get filterUdyam;

  /// No description provided for @filterStartup.
  ///
  /// In en, this message translates to:
  /// **'Startup'**
  String get filterStartup;

  /// No description provided for @filterSubsidy.
  ///
  /// In en, this message translates to:
  /// **'Subsidy'**
  String get filterSubsidy;

  /// No description provided for @filterCollateralFree.
  ///
  /// In en, this message translates to:
  /// **'Collateral-Free'**
  String get filterCollateralFree;

  /// No description provided for @discoverTitle.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get discoverTitle;

  /// No description provided for @browseByCategories.
  ///
  /// In en, this message translates to:
  /// **'Browse by Categories'**
  String get browseByCategories;

  /// No description provided for @featuredCollections.
  ///
  /// In en, this message translates to:
  /// **'Featured Collections'**
  String get featuredCollections;

  /// No description provided for @browseByMinistry.
  ///
  /// In en, this message translates to:
  /// **'Browse by Ministry'**
  String get browseByMinistry;

  /// No description provided for @browseByState.
  ///
  /// In en, this message translates to:
  /// **'Browse by State'**
  String get browseByState;

  /// No description provided for @smartAssessment.
  ///
  /// In en, this message translates to:
  /// **'Smart Assessment'**
  String get smartAssessment;

  /// No description provided for @viewAllCategories.
  ///
  /// In en, this message translates to:
  /// **'View All Categories'**
  String get viewAllCategories;

  /// No description provided for @schemeCountFormat.
  ///
  /// In en, this message translates to:
  /// **'{count} Schemes'**
  String schemeCountFormat(Object count);

  /// No description provided for @exploreTopCuratedCollections.
  ///
  /// In en, this message translates to:
  /// **'Explore top curated collections'**
  String get exploreTopCuratedCollections;

  /// No description provided for @schemesByGovernmentMinistries.
  ///
  /// In en, this message translates to:
  /// **'Schemes by Government Ministries'**
  String get schemesByGovernmentMinistries;

  /// No description provided for @schemesByStatesAndUnionTerritories.
  ///
  /// In en, this message translates to:
  /// **'Schemes by States & Union Territories'**
  String get schemesByStatesAndUnionTerritories;

  /// No description provided for @personalizedRecommendationMatches.
  ///
  /// In en, this message translates to:
  /// **'Personalized recommendation matches'**
  String get personalizedRecommendationMatches;

  /// No description provided for @savedTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved Schemes'**
  String get savedTitle;

  /// No description provided for @allSavedTabFormat.
  ///
  /// In en, this message translates to:
  /// **'All Saved ({count})'**
  String allSavedTabFormat(Object count);

  /// No description provided for @recentlyAddedTab.
  ///
  /// In en, this message translates to:
  /// **'Recently Added'**
  String get recentlyAddedTab;

  /// No description provided for @noSavedSchemes.
  ///
  /// In en, this message translates to:
  /// **'No Saved Schemes Yet'**
  String get noSavedSchemes;

  /// No description provided for @noSavedSchemesDesc.
  ///
  /// In en, this message translates to:
  /// **'Bookmark schemes while browsing to view them offline anytime.'**
  String get noSavedSchemesDesc;

  /// No description provided for @manageSaved.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get manageSaved;

  /// No description provided for @doneManaging.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get doneManaging;

  /// No description provided for @clearAllSaved.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAllSaved;

  /// No description provided for @schemeRemovedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Scheme removed from saved list'**
  String get schemeRemovedSnackbar;

  /// No description provided for @confirmClearSavedTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear Saved Schemes'**
  String get confirmClearSavedTitle;

  /// No description provided for @confirmClearSavedMsg.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove all saved schemes?'**
  String get confirmClearSavedMsg;

  /// No description provided for @profileSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile & Settings'**
  String get profileSettingsTitle;

  /// No description provided for @profileGroupHeader.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileGroupHeader;

  /// No description provided for @completeProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete Profile'**
  String get completeProfileTitle;

  /// No description provided for @profileCompletionFormat.
  ///
  /// In en, this message translates to:
  /// **'{percent}% completed'**
  String profileCompletionFormat(Object percent);

  /// No description provided for @preferencesGroupHeader.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferencesGroupHeader;

  /// No description provided for @languageSetting.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSetting;

  /// No description provided for @navigationModeSetting.
  ///
  /// In en, this message translates to:
  /// **'Navigation Mode'**
  String get navigationModeSetting;

  /// No description provided for @navigationModeRegular.
  ///
  /// In en, this message translates to:
  /// **'Regular'**
  String get navigationModeRegular;

  /// No description provided for @navigationModeCompanion.
  ///
  /// In en, this message translates to:
  /// **'Companion'**
  String get navigationModeCompanion;

  /// No description provided for @notificationsGroupHeader.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsGroupHeader;

  /// No description provided for @pushNotificationsSetting.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get pushNotificationsSetting;

  /// No description provided for @notificationsEnabled.
  ///
  /// In en, this message translates to:
  /// **'Notifications enabled'**
  String get notificationsEnabled;

  /// No description provided for @notificationsDisabled.
  ///
  /// In en, this message translates to:
  /// **'Notifications disabled'**
  String get notificationsDisabled;

  /// No description provided for @securityPrivacyGroupHeader.
  ///
  /// In en, this message translates to:
  /// **'Security & Privacy'**
  String get securityPrivacyGroupHeader;

  /// No description provided for @privacyPolicySetting.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicySetting;

  /// No description provided for @privacyPolicyContent.
  ///
  /// In en, this message translates to:
  /// **'Your privacy is important to us. All personal data is encrypted and saved locally on this device.'**
  String get privacyPolicyContent;

  /// No description provided for @termsConditionsSetting.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get termsConditionsSetting;

  /// No description provided for @termsConditionsContent.
  ///
  /// In en, this message translates to:
  /// **'By using MSS, you agree to our terms of service. All scheme information is aggregated from official government portals.'**
  String get termsConditionsContent;

  /// No description provided for @deleteAccountSetting.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccountSetting;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountMsg.
  ///
  /// In en, this message translates to:
  /// **'This action is irreversible. All your saved profiles, bookmarks, and questionnaire answers will be permanently deleted.'**
  String get deleteAccountMsg;

  /// No description provided for @deleteButton.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteButton;

  /// No description provided for @supportGroupHeader.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get supportGroupHeader;

  /// No description provided for @helpFaqSetting.
  ///
  /// In en, this message translates to:
  /// **'Help & FAQ'**
  String get helpFaqSetting;

  /// No description provided for @contactUsSetting.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get contactUsSetting;

  /// No description provided for @logoutButton.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logoutButton;

  /// No description provided for @confirmLogoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Logout'**
  String get confirmLogoutTitle;

  /// No description provided for @confirmLogoutMsg.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out from MSS?'**
  String get confirmLogoutMsg;

  /// No description provided for @dialogDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get dialogDone;

  /// No description provided for @dialogCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get dialogCancel;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profileVerified.
  ///
  /// In en, this message translates to:
  /// **'Profile Verified'**
  String get profileVerified;

  /// No description provided for @profileIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Incomplete'**
  String get profileIncomplete;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @userInformation.
  ///
  /// In en, this message translates to:
  /// **'User Information'**
  String get userInformation;

  /// No description provided for @eligibilityProfessionalDetails.
  ///
  /// In en, this message translates to:
  /// **'Eligibility & Professional Details'**
  String get eligibilityProfessionalDetails;

  /// No description provided for @businessInformation.
  ///
  /// In en, this message translates to:
  /// **'Business Information'**
  String get businessInformation;

  /// No description provided for @labelFullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get labelFullName;

  /// No description provided for @labelAge.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get labelAge;

  /// No description provided for @labelGender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get labelGender;

  /// No description provided for @labelLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get labelLocation;

  /// No description provided for @labelEducationLevel.
  ///
  /// In en, this message translates to:
  /// **'Education Level'**
  String get labelEducationLevel;

  /// No description provided for @labelEmployment.
  ///
  /// In en, this message translates to:
  /// **'Employment'**
  String get labelEmployment;

  /// No description provided for @labelCommunityCategory.
  ///
  /// In en, this message translates to:
  /// **'Community Category'**
  String get labelCommunityCategory;

  /// No description provided for @labelAnnualIncome.
  ///
  /// In en, this message translates to:
  /// **'Annual Income'**
  String get labelAnnualIncome;

  /// No description provided for @labelDifferentlyAbled.
  ///
  /// In en, this message translates to:
  /// **'Differently Abled'**
  String get labelDifferentlyAbled;

  /// No description provided for @labelExServiceman.
  ///
  /// In en, this message translates to:
  /// **'Ex-Serviceman / Veteran'**
  String get labelExServiceman;

  /// No description provided for @labelBusinessStage.
  ///
  /// In en, this message translates to:
  /// **'Business Stage'**
  String get labelBusinessStage;

  /// No description provided for @labelIndustry.
  ///
  /// In en, this message translates to:
  /// **'Industry'**
  String get labelIndustry;

  /// No description provided for @labelFundingRequired.
  ///
  /// In en, this message translates to:
  /// **'Funding Required'**
  String get labelFundingRequired;

  /// No description provided for @labelRegNumbers.
  ///
  /// In en, this message translates to:
  /// **'Reg. Numbers'**
  String get labelRegNumbers;

  /// No description provided for @subSavedSchemes.
  ///
  /// In en, this message translates to:
  /// **'View your bookmarked schemes'**
  String get subSavedSchemes;

  /// No description provided for @subLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred language'**
  String get subLanguage;

  /// No description provided for @subSettings.
  ///
  /// In en, this message translates to:
  /// **'Manage app preferences'**
  String get subSettings;

  /// No description provided for @subPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy and data settings'**
  String get subPrivacy;

  /// No description provided for @subHelpSupport.
  ///
  /// In en, this message translates to:
  /// **'Get help and contact support'**
  String get subHelpSupport;

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutTitle;

  /// No description provided for @subAbout.
  ///
  /// In en, this message translates to:
  /// **'About MSS app'**
  String get subAbout;

  /// No description provided for @subLogout.
  ///
  /// In en, this message translates to:
  /// **'Logout from your account'**
  String get subLogout;

  /// No description provided for @aboutAppDescription.
  ///
  /// In en, this message translates to:
  /// **'Empowering citizens with real-time tracking, eligibility scanning and downloads for all state and central Government schemes in India.'**
  String get aboutAppDescription;

  /// No description provided for @profilePhotoTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile Photo'**
  String get profilePhotoTitle;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get chooseFromGallery;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// No description provided for @removePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove Photo'**
  String get removePhoto;

  /// No description provided for @genderMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get genderMale;

  /// No description provided for @genderFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get genderFemale;

  /// No description provided for @genderOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get genderOther;

  /// No description provided for @empStudent.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get empStudent;

  /// No description provided for @empFarmer.
  ///
  /// In en, this message translates to:
  /// **'Farmer'**
  String get empFarmer;

  /// No description provided for @empSalaried.
  ///
  /// In en, this message translates to:
  /// **'Salaried'**
  String get empSalaried;

  /// No description provided for @empSelfEmployed.
  ///
  /// In en, this message translates to:
  /// **'Self-Employed'**
  String get empSelfEmployed;

  /// No description provided for @empUnemployed.
  ///
  /// In en, this message translates to:
  /// **'Unemployed'**
  String get empUnemployed;

  /// No description provided for @empRetired.
  ///
  /// In en, this message translates to:
  /// **'Retired'**
  String get empRetired;

  /// No description provided for @commGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get commGeneral;

  /// No description provided for @commObc.
  ///
  /// In en, this message translates to:
  /// **'OBC'**
  String get commObc;

  /// No description provided for @commEws.
  ///
  /// In en, this message translates to:
  /// **'EWS'**
  String get commEws;

  /// No description provided for @commSc.
  ///
  /// In en, this message translates to:
  /// **'SC'**
  String get commSc;

  /// No description provided for @commSt.
  ///
  /// In en, this message translates to:
  /// **'ST'**
  String get commSt;

  /// No description provided for @commOthers.
  ///
  /// In en, this message translates to:
  /// **'Others'**
  String get commOthers;

  /// No description provided for @incUnder1_5.
  ///
  /// In en, this message translates to:
  /// **'Under ₹1.5 Lakhs'**
  String get incUnder1_5;

  /// No description provided for @inc1_5To3.
  ///
  /// In en, this message translates to:
  /// **'₹1.5 Lakhs - ₹3 Lakhs'**
  String get inc1_5To3;

  /// No description provided for @inc3To5.
  ///
  /// In en, this message translates to:
  /// **'₹3 Lakhs - ₹5 Lakhs'**
  String get inc3To5;

  /// No description provided for @inc5To8.
  ///
  /// In en, this message translates to:
  /// **'₹5 Lakhs - ₹8 Lakhs'**
  String get inc5To8;

  /// No description provided for @incAbove8.
  ///
  /// In en, this message translates to:
  /// **'Above ₹8 Lakhs'**
  String get incAbove8;

  /// No description provided for @valYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get valYes;

  /// No description provided for @valNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get valNo;

  /// No description provided for @valNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get valNone;

  /// No description provided for @schemeDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Scheme Details'**
  String get schemeDetailsTitle;

  /// No description provided for @tabOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get tabOverview;

  /// No description provided for @tabBenefits.
  ///
  /// In en, this message translates to:
  /// **'Benefits'**
  String get tabBenefits;

  /// No description provided for @tabEligibility.
  ///
  /// In en, this message translates to:
  /// **'Eligibility'**
  String get tabEligibility;

  /// No description provided for @tabDocuments.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get tabDocuments;

  /// No description provided for @tabServices.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get tabServices;

  /// No description provided for @tabProcess.
  ///
  /// In en, this message translates to:
  /// **'Process'**
  String get tabProcess;

  /// No description provided for @schemeAtAGlance.
  ///
  /// In en, this message translates to:
  /// **'Scheme at a glance'**
  String get schemeAtAGlance;

  /// No description provided for @benefitsDetails.
  ///
  /// In en, this message translates to:
  /// **'Benefits Details'**
  String get benefitsDetails;

  /// No description provided for @eligibilityCriteria.
  ///
  /// In en, this message translates to:
  /// **'Eligibility Criteria'**
  String get eligibilityCriteria;

  /// No description provided for @requiredDocuments.
  ///
  /// In en, this message translates to:
  /// **'Required Documents'**
  String get requiredDocuments;

  /// No description provided for @requiredServices.
  ///
  /// In en, this message translates to:
  /// **'Required Services'**
  String get requiredServices;

  /// No description provided for @applicationProcessHeader.
  ///
  /// In en, this message translates to:
  /// **'Application Process'**
  String get applicationProcessHeader;

  /// No description provided for @officialInformation.
  ///
  /// In en, this message translates to:
  /// **'Official scheme information'**
  String get officialInformation;

  /// No description provided for @lastUpdatedFormat.
  ///
  /// In en, this message translates to:
  /// **'Last updated: {date}'**
  String lastUpdatedFormat(Object date);

  /// No description provided for @sourceButton.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get sourceButton;

  /// No description provided for @applyNowButton.
  ///
  /// In en, this message translates to:
  /// **'Apply Now'**
  String get applyNowButton;

  /// No description provided for @saveSchemeButton.
  ///
  /// In en, this message translates to:
  /// **'Save Scheme'**
  String get saveSchemeButton;

  /// No description provided for @savedSchemeButton.
  ///
  /// In en, this message translates to:
  /// **'Saved Scheme'**
  String get savedSchemeButton;

  /// No description provided for @noVerifiedLink.
  ///
  /// In en, this message translates to:
  /// **'No verified official link is available.'**
  String get noVerifiedLink;

  /// No description provided for @couldNotOpenWebsite.
  ///
  /// In en, this message translates to:
  /// **'Could not open the official website.'**
  String get couldNotOpenWebsite;

  /// No description provided for @noDocumentsPublished.
  ///
  /// In en, this message translates to:
  /// **'No document list is published for this scheme. Check the official source before applying.'**
  String get noDocumentsPublished;

  /// No description provided for @noServicesRequiredMsg.
  ///
  /// In en, this message translates to:
  /// **'No separate service requirement is listed for this scheme.'**
  String get noServicesRequiredMsg;

  /// No description provided for @getDocumentOnline.
  ///
  /// In en, this message translates to:
  /// **'Get Document Online'**
  String get getDocumentOnline;

  /// No description provided for @issuedByFormat.
  ///
  /// In en, this message translates to:
  /// **'Issued by: {authority}'**
  String issuedByFormat(Object authority);

  /// No description provided for @estimatedCostFormat.
  ///
  /// In en, this message translates to:
  /// **'Estimated cost: {cost}'**
  String estimatedCostFormat(Object cost);

  /// No description provided for @verificationNote.
  ///
  /// In en, this message translates to:
  /// **'Verification note'**
  String get verificationNote;

  /// No description provided for @benefitSubsidy.
  ///
  /// In en, this message translates to:
  /// **'Subsidy'**
  String get benefitSubsidy;

  /// No description provided for @benefitAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get benefitAmount;

  /// No description provided for @benefitMaximum.
  ///
  /// In en, this message translates to:
  /// **'Maximum'**
  String get benefitMaximum;

  /// No description provided for @benefitSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get benefitSupport;

  /// No description provided for @matchPercentageFormat.
  ///
  /// In en, this message translates to:
  /// **'{percent}% Match'**
  String matchPercentageFormat(Object percent);

  /// No description provided for @highlyRelevant.
  ///
  /// In en, this message translates to:
  /// **'Highly relevant'**
  String get highlyRelevant;

  /// No description provided for @levelSchemeFormat.
  ///
  /// In en, this message translates to:
  /// **'{level} Scheme'**
  String levelSchemeFormat(Object level);

  /// No description provided for @processStepSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Complete this phase to progress further.'**
  String get processStepSubtitle;

  /// No description provided for @badgeRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get badgeRequired;

  /// No description provided for @badgeConditional.
  ///
  /// In en, this message translates to:
  /// **'Conditional'**
  String get badgeConditional;

  /// No description provided for @filterDistrict.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get filterDistrict;

  /// No description provided for @filterMinistry.
  ///
  /// In en, this message translates to:
  /// **'Ministry'**
  String get filterMinistry;

  /// No description provided for @filterDepartment.
  ///
  /// In en, this message translates to:
  /// **'Department'**
  String get filterDepartment;

  /// No description provided for @filterCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get filterCategory;

  /// No description provided for @labelCommunity.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get labelCommunity;

  /// No description provided for @labelOccupation.
  ///
  /// In en, this message translates to:
  /// **'Occupation'**
  String get labelOccupation;

  /// No description provided for @labelEducation.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get labelEducation;

  /// No description provided for @labelFirstGenGraduate.
  ///
  /// In en, this message translates to:
  /// **'First Generation Graduate'**
  String get labelFirstGenGraduate;

  /// No description provided for @labelDisability.
  ///
  /// In en, this message translates to:
  /// **'Disability'**
  String get labelDisability;

  /// No description provided for @filterSchemeStatus.
  ///
  /// In en, this message translates to:
  /// **'Scheme Status'**
  String get filterSchemeStatus;

  /// No description provided for @filterOnlineOffline.
  ///
  /// In en, this message translates to:
  /// **'Online / Offline'**
  String get filterOnlineOffline;

  /// No description provided for @filterCentralStateScheme.
  ///
  /// In en, this message translates to:
  /// **'Central / State Scheme'**
  String get filterCentralStateScheme;

  /// No description provided for @filterClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get filterClearAll;

  /// No description provided for @validationSelectDob.
  ///
  /// In en, this message translates to:
  /// **'Please select your Date of Birth'**
  String get validationSelectDob;

  /// No description provided for @notifTooltipMarkRead.
  ///
  /// In en, this message translates to:
  /// **'Mark selected as read'**
  String get notifTooltipMarkRead;

  /// No description provided for @notifTooltipDeleteSelected.
  ///
  /// In en, this message translates to:
  /// **'Delete selected'**
  String get notifTooltipDeleteSelected;

  /// No description provided for @notifNewSchemeAlertsTitle.
  ///
  /// In en, this message translates to:
  /// **'New Scheme Alerts'**
  String get notifNewSchemeAlertsTitle;

  /// No description provided for @notifNewSchemeAlertsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Stay informed about newly launched schemes'**
  String get notifNewSchemeAlertsSubtitle;

  /// No description provided for @notifDeadlineRemindersTitle.
  ///
  /// In en, this message translates to:
  /// **'Deadline Reminders'**
  String get notifDeadlineRemindersTitle;

  /// No description provided for @notifDeadlineRemindersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Don\'t miss important application deadlines'**
  String get notifDeadlineRemindersSubtitle;

  /// No description provided for @notifGovtUpdatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Government Updates'**
  String get notifGovtUpdatesTitle;

  /// No description provided for @notifGovtUpdatesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Important announcements and updates'**
  String get notifGovtUpdatesSubtitle;

  /// No description provided for @notifProfileRemindersTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile Completion Reminders'**
  String get notifProfileRemindersTitle;

  /// No description provided for @notifProfileRemindersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile to get better recommendations'**
  String get notifProfileRemindersSubtitle;

  /// No description provided for @navChooseYourPrefix.
  ///
  /// In en, this message translates to:
  /// **'Choose Your '**
  String get navChooseYourPrefix;

  /// No description provided for @navExperienceSuffix.
  ///
  /// In en, this message translates to:
  /// **'Experience'**
  String get navExperienceSuffix;

  /// No description provided for @navRegularNavigationTitle.
  ///
  /// In en, this message translates to:
  /// **'Regular Navigation'**
  String get navRegularNavigationTitle;

  /// No description provided for @navModeRegularSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Browse and explore the app independently.'**
  String get navModeRegularSubtitle;

  /// No description provided for @navAiCompanionTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Companion'**
  String get navAiCompanionTitle;

  /// No description provided for @navModeCompanionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Let your AI guide you step by step.'**
  String get navModeCompanionSubtitle;

  /// No description provided for @navSwitchAnytimeTitle.
  ///
  /// In en, this message translates to:
  /// **'Switch Anytime'**
  String get navSwitchAnytimeTitle;

  /// No description provided for @settingsRegularSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Traditional clean list and tab view layout'**
  String get settingsRegularSubtitle;

  /// No description provided for @settingsCompanionTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Companion (Saarthi)'**
  String get settingsCompanionTitle;

  /// No description provided for @settingsCompanionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Voice-first AI guided conversational view'**
  String get settingsCompanionSubtitle;

  /// No description provided for @navSwitchAnytimeDesc.
  ///
  /// In en, this message translates to:
  /// **'You can change your navigation mode later from Settings.'**
  String get navSwitchAnytimeDesc;

  /// No description provided for @helpContactEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Contact Email Address'**
  String get helpContactEmailLabel;

  /// No description provided for @helpContactEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email for follow-up'**
  String get helpContactEmailHint;

  /// No description provided for @helpDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get helpDescriptionLabel;

  /// No description provided for @helpDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Describe the issue in detail...'**
  String get helpDescriptionHint;

  /// No description provided for @helpSuggestionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Your suggestions'**
  String get helpSuggestionsLabel;

  /// No description provided for @helpSuggestionsHint.
  ///
  /// In en, this message translates to:
  /// **'What can we do better?'**
  String get helpSuggestionsHint;

  /// No description provided for @companionVoiceUnavailableRetry.
  ///
  /// In en, this message translates to:
  /// **'Voice service is unavailable. Tap retry.'**
  String get companionVoiceUnavailableRetry;

  /// No description provided for @companionSignInRetryVoice.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again, then retry voice.'**
  String get companionSignInRetryVoice;

  /// No description provided for @companionCheckInternetRetryVoice.
  ///
  /// In en, this message translates to:
  /// **'Check your internet, then retry voice.'**
  String get companionCheckInternetRetryVoice;

  /// No description provided for @companionVoiceConnectFailedRetry.
  ///
  /// In en, this message translates to:
  /// **'Voice service could not connect. Tap retry.'**
  String get companionVoiceConnectFailedRetry;

  /// No description provided for @companionGenericErrorRetry.
  ///
  /// In en, this message translates to:
  /// **'An error occurred. Please try again.'**
  String get companionGenericErrorRetry;

  /// No description provided for @companionConnectionNeedsAttention.
  ///
  /// In en, this message translates to:
  /// **'Connection needs attention'**
  String get companionConnectionNeedsAttention;

  /// No description provided for @companionConnectingShort.
  ///
  /// In en, this message translates to:
  /// **'Connecting'**
  String get companionConnectingShort;

  /// No description provided for @companionListeningToYou.
  ///
  /// In en, this message translates to:
  /// **'Listening to you'**
  String get companionListeningToYou;

  /// No description provided for @companionCheckingYourDetails.
  ///
  /// In en, this message translates to:
  /// **'Checking your details'**
  String get companionCheckingYourDetails;

  /// No description provided for @companionSpeakingNow.
  ///
  /// In en, this message translates to:
  /// **'Speaking now'**
  String get companionSpeakingNow;

  /// No description provided for @companionReadyToHelp.
  ///
  /// In en, this message translates to:
  /// **'Ready to help'**
  String get companionReadyToHelp;

  /// No description provided for @companionVoiceConnected.
  ///
  /// In en, this message translates to:
  /// **'Voice connected'**
  String get companionVoiceConnected;

  /// No description provided for @companionVoiceOffline.
  ///
  /// In en, this message translates to:
  /// **'Voice offline'**
  String get companionVoiceOffline;

  /// No description provided for @companionIntroPrefix.
  ///
  /// In en, this message translates to:
  /// **'I\'m'**
  String get companionIntroPrefix;

  /// No description provided for @companionIntroSuffix.
  ///
  /// In en, this message translates to:
  /// **', your AI companion for\nMSME success.'**
  String get companionIntroSuffix;

  /// No description provided for @companionEmptyStateHint.
  ///
  /// In en, this message translates to:
  /// **'Tell me what support you need. I will ask one detail at a time.'**
  String get companionEmptyStateHint;

  /// No description provided for @companionScrollToLatest.
  ///
  /// In en, this message translates to:
  /// **'Latest'**
  String get companionScrollToLatest;

  /// No description provided for @companionSpeakingBadge.
  ///
  /// In en, this message translates to:
  /// **'Speaking'**
  String get companionSpeakingBadge;

  /// No description provided for @companionRankedResultsCaption.
  ///
  /// In en, this message translates to:
  /// **'Ranked from the details you shared. Final eligibility is confirmed by the department.'**
  String get companionRankedResultsCaption;

  /// No description provided for @companionReviewMatch.
  ///
  /// In en, this message translates to:
  /// **'Review match'**
  String get companionReviewMatch;

  /// No description provided for @companionOfficialSourceChecked.
  ///
  /// In en, this message translates to:
  /// **'Official source checked'**
  String get companionOfficialSourceChecked;

  /// No description provided for @companionOfficialSourceCheckedConfidence.
  ///
  /// In en, this message translates to:
  /// **'Official source checked · {confidence} confidence'**
  String companionOfficialSourceCheckedConfidence(Object confidence);

  /// No description provided for @companionVerifyWithDepartment.
  ///
  /// In en, this message translates to:
  /// **'Verify with the department'**
  String get companionVerifyWithDepartment;

  /// No description provided for @companionViewEligibility.
  ///
  /// In en, this message translates to:
  /// **'View eligibility'**
  String get companionViewEligibility;

  /// No description provided for @companionYouTimestampLabel.
  ///
  /// In en, this message translates to:
  /// **'You  {time}'**
  String companionYouTimestampLabel(Object time);

  /// No description provided for @companionAiTimestampLabel.
  ///
  /// In en, this message translates to:
  /// **'MSS Saarthi  {time}'**
  String companionAiTimestampLabel(Object time);

  /// No description provided for @companionAskAnything.
  ///
  /// In en, this message translates to:
  /// **'Ask Saarthi anything...'**
  String get companionAskAnything;

  /// No description provided for @companionTapToSpeakHint.
  ///
  /// In en, this message translates to:
  /// **'Tap below and speak your question'**
  String get companionTapToSpeakHint;

  /// No description provided for @companionRetryVoice.
  ///
  /// In en, this message translates to:
  /// **'Retry voice'**
  String get companionRetryVoice;

  /// No description provided for @companionSecureLiveSession.
  ///
  /// In en, this message translates to:
  /// **'Secure live voice session'**
  String get companionSecureLiveSession;

  /// No description provided for @companionLiveConnectionRequired.
  ///
  /// In en, this message translates to:
  /// **'Live voice connection required'**
  String get companionLiveConnectionRequired;

  /// No description provided for @companionStartSpeakingSemantic.
  ///
  /// In en, this message translates to:
  /// **'Start speaking to Saarthi'**
  String get companionStartSpeakingSemantic;

  /// No description provided for @companionTapToSpeak.
  ///
  /// In en, this message translates to:
  /// **'Tap to speak'**
  String get companionTapToSpeak;

  /// No description provided for @companionStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get companionStop;

  /// No description provided for @companionInterrupt.
  ///
  /// In en, this message translates to:
  /// **'Interrupt'**
  String get companionInterrupt;

  /// No description provided for @companionSpeak.
  ///
  /// In en, this message translates to:
  /// **'Speak'**
  String get companionSpeak;

  /// No description provided for @companionEnd.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get companionEnd;

  /// No description provided for @companionVoiceNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Voice is not connected'**
  String get companionVoiceNotConnected;

  /// No description provided for @companionConnectingSecurely.
  ///
  /// In en, this message translates to:
  /// **'Connecting securely'**
  String get companionConnectingSecurely;

  /// No description provided for @companionFindingBestMatch.
  ///
  /// In en, this message translates to:
  /// **'Finding the best match'**
  String get companionFindingBestMatch;

  /// No description provided for @companionSaarthiIsSpeaking.
  ///
  /// In en, this message translates to:
  /// **'Saarthi is speaking'**
  String get companionSaarthiIsSpeaking;

  /// No description provided for @companionReadyShort.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get companionReadyShort;

  /// No description provided for @welcomeMeetPrefix.
  ///
  /// In en, this message translates to:
  /// **'Meet'**
  String get welcomeMeetPrefix;

  /// No description provided for @welcomeIntroLine1.
  ///
  /// In en, this message translates to:
  /// **'I\'m Saarthi, your smart assistant.'**
  String get welcomeIntroLine1;

  /// No description provided for @welcomeIntroLine2.
  ///
  /// In en, this message translates to:
  /// **'I\'ll help you discover the right schemes, explain everything simply, and guide you at every step.'**
  String get welcomeIntroLine2;

  /// No description provided for @welcomeSectionHeader.
  ///
  /// In en, this message translates to:
  /// **'Saarthi can help you with'**
  String get welcomeSectionHeader;

  /// No description provided for @welcomeFeatureTalkNaturally.
  ///
  /// In en, this message translates to:
  /// **'Talk Naturally'**
  String get welcomeFeatureTalkNaturally;

  /// No description provided for @welcomeFeatureFindSchemes.
  ///
  /// In en, this message translates to:
  /// **'Find Right Schemes'**
  String get welcomeFeatureFindSchemes;

  /// No description provided for @welcomeFeatureBusinessRoadmap.
  ///
  /// In en, this message translates to:
  /// **'Business Roadmap'**
  String get welcomeFeatureBusinessRoadmap;

  /// No description provided for @welcomeFeatureApplicationSupport.
  ///
  /// In en, this message translates to:
  /// **'Application Support'**
  String get welcomeFeatureApplicationSupport;

  /// No description provided for @welcomeChooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose Language'**
  String get welcomeChooseLanguage;

  /// No description provided for @welcomeChooseLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred language so Saarthi can talk to you better.'**
  String get welcomeChooseLanguageSubtitle;

  /// No description provided for @welcomeVoiceLabel.
  ///
  /// In en, this message translates to:
  /// **'Voice'**
  String get welcomeVoiceLabel;

  /// No description provided for @welcomeVoiceNatural.
  ///
  /// In en, this message translates to:
  /// **'Natural'**
  String get welcomeVoiceNatural;

  /// No description provided for @welcomeVoiceClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get welcomeVoiceClear;

  /// No description provided for @welcomePreviewVoiceTooltip.
  ///
  /// In en, this message translates to:
  /// **'Preview in English and Tamil'**
  String get welcomePreviewVoiceTooltip;

  /// No description provided for @welcomeChangeAnytimeNote.
  ///
  /// In en, this message translates to:
  /// **'You can change this anytime in settings.'**
  String get welcomeChangeAnytimeNote;

  /// No description provided for @welcomeLetsBegin.
  ///
  /// In en, this message translates to:
  /// **'Let\'s Begin'**
  String get welcomeLetsBegin;

  /// No description provided for @voiceLanguageAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get voiceLanguageAuto;

  /// No description provided for @voiceStatusSpeaking.
  ///
  /// In en, this message translates to:
  /// **'Speaking...'**
  String get voiceStatusSpeaking;

  /// No description provided for @voiceStatusListening.
  ///
  /// In en, this message translates to:
  /// **'Listening...'**
  String get voiceStatusListening;

  /// No description provided for @voiceStatusProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get voiceStatusProcessing;

  /// No description provided for @voiceStatusUnderstanding.
  ///
  /// In en, this message translates to:
  /// **'Understanding...'**
  String get voiceStatusUnderstanding;

  /// No description provided for @voiceStatusOneQuestion.
  ///
  /// In en, this message translates to:
  /// **'One question'**
  String get voiceStatusOneQuestion;

  /// No description provided for @voiceStatusMatchesFound.
  ///
  /// In en, this message translates to:
  /// **'Matches found'**
  String get voiceStatusMatchesFound;

  /// No description provided for @voiceStatusNeedsMoreDetail.
  ///
  /// In en, this message translates to:
  /// **'Needs more detail'**
  String get voiceStatusNeedsMoreDetail;

  /// No description provided for @voiceStatusFinding.
  ///
  /// In en, this message translates to:
  /// **'Finding...'**
  String get voiceStatusFinding;

  /// No description provided for @voiceStatusFoundCount.
  ///
  /// In en, this message translates to:
  /// **'Found {count}'**
  String voiceStatusFoundCount(Object count);

  /// No description provided for @voiceRecommendedBySaarthiReason.
  ///
  /// In en, this message translates to:
  /// **'Recommended by Saarthi from the verified catalog'**
  String get voiceRecommendedBySaarthiReason;

  /// No description provided for @voiceRecognitionUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Voice recognition is not available on this device.'**
  String get voiceRecognitionUnavailable;

  /// No description provided for @voiceRecognitionStartFailed.
  ///
  /// In en, this message translates to:
  /// **'Voice recognition could not start. Please try again.'**
  String get voiceRecognitionStartFailed;

  /// No description provided for @voiceSearchFailed.
  ///
  /// In en, this message translates to:
  /// **'I could not search right now. Please try again.'**
  String get voiceSearchFailed;

  /// No description provided for @voiceUseValue.
  ///
  /// In en, this message translates to:
  /// **'Use value'**
  String get voiceUseValue;

  /// No description provided for @voiceReviewProfileUpdates.
  ///
  /// In en, this message translates to:
  /// **'Review profile updates'**
  String get voiceReviewProfileUpdates;

  /// No description provided for @voiceKeepSessionOnly.
  ///
  /// In en, this message translates to:
  /// **'Keep session only'**
  String get voiceKeepSessionOnly;

  /// No description provided for @voiceSaveConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Save confirmed'**
  String get voiceSaveConfirmed;

  /// No description provided for @voiceProfileSavedMessage.
  ///
  /// In en, this message translates to:
  /// **'Confirmed details saved to your profile.'**
  String get voiceProfileSavedMessage;

  /// No description provided for @voiceCloudDisclosure.
  ///
  /// In en, this message translates to:
  /// **'Live audio is processed securely. This app does not save audio or raw transcripts.'**
  String get voiceCloudDisclosure;

  /// No description provided for @voiceNoConfidentMatch.
  ///
  /// In en, this message translates to:
  /// **'No confident scheme match yet. Tell me a little more about your situation.'**
  String get voiceNoConfidentMatch;

  /// No description provided for @voiceHeaderTalkToSaarthi.
  ///
  /// In en, this message translates to:
  /// **'Talk to Saarthi'**
  String get voiceHeaderTalkToSaarthi;

  /// No description provided for @voiceUnmute.
  ///
  /// In en, this message translates to:
  /// **'Unmute'**
  String get voiceUnmute;

  /// No description provided for @voiceMute.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get voiceMute;

  /// No description provided for @voiceCancelAssistantTooltip.
  ///
  /// In en, this message translates to:
  /// **'Cancel assistant'**
  String get voiceCancelAssistantTooltip;

  /// No description provided for @voiceTellMeNaturally.
  ///
  /// In en, this message translates to:
  /// **'Tell me your situation naturally...'**
  String get voiceTellMeNaturally;

  /// No description provided for @voiceSuggestionBusinessLoans.
  ///
  /// In en, this message translates to:
  /// **'Business loans'**
  String get voiceSuggestionBusinessLoans;

  /// No description provided for @voiceSuggestionCollegeScholarship.
  ///
  /// In en, this message translates to:
  /// **'College scholarship'**
  String get voiceSuggestionCollegeScholarship;

  /// No description provided for @voiceSuggestionFarmerSubsidy.
  ///
  /// In en, this message translates to:
  /// **'Farmer subsidy'**
  String get voiceSuggestionFarmerSubsidy;

  /// No description provided for @voiceStopListeningSemantic.
  ///
  /// In en, this message translates to:
  /// **'Stop listening'**
  String get voiceStopListeningSemantic;

  /// No description provided for @voiceStartListeningSemantic.
  ///
  /// In en, this message translates to:
  /// **'Start listening'**
  String get voiceStartListeningSemantic;

  /// No description provided for @voiceTypeToSaarthiHint.
  ///
  /// In en, this message translates to:
  /// **'Type to Saarthi...'**
  String get voiceTypeToSaarthiHint;

  /// No description provided for @voiceSendMessageTooltip.
  ///
  /// In en, this message translates to:
  /// **'Send message'**
  String get voiceSendMessageTooltip;

  /// No description provided for @voiceLanguageSemantic.
  ///
  /// In en, this message translates to:
  /// **'Voice language {language}'**
  String voiceLanguageSemantic(Object language);

  /// No description provided for @voiceWhatIUnderstood.
  ///
  /// In en, this message translates to:
  /// **'What I understood'**
  String get voiceWhatIUnderstood;

  /// No description provided for @voiceRepeatQuestionTooltip.
  ///
  /// In en, this message translates to:
  /// **'Repeat question'**
  String get voiceRepeatQuestionTooltip;

  /// No description provided for @voiceSpeechOutputUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Speech output is unavailable; tap the microphone to answer.'**
  String get voiceSpeechOutputUnavailable;

  /// No description provided for @voiceSchemesSuitedToSituation.
  ///
  /// In en, this message translates to:
  /// **'Schemes suited to your situation'**
  String get voiceSchemesSuitedToSituation;

  /// No description provided for @voiceViewAllResults.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get voiceViewAllResults;

  /// No description provided for @voiceReviewAndSaveDetails.
  ///
  /// In en, this message translates to:
  /// **'Review and save confirmed details'**
  String get voiceReviewAndSaveDetails;

  /// No description provided for @voiceOpenOfficialSource.
  ///
  /// In en, this message translates to:
  /// **'Open official source'**
  String get voiceOpenOfficialSource;

  /// No description provided for @voiceGroundingChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking official sources…'**
  String get voiceGroundingChecking;

  /// No description provided for @voiceGroundingFoundSources.
  ///
  /// In en, this message translates to:
  /// **'Grounded online · {count} official {sources}'**
  String voiceGroundingFoundSources(Object count, Object sources);

  /// No description provided for @voiceGroundingUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Offline · using private on-device knowledge'**
  String get voiceGroundingUnavailable;

  /// No description provided for @voiceGroundingNoSources.
  ///
  /// In en, this message translates to:
  /// **'Official page unavailable · using the verified local catalog'**
  String get voiceGroundingNoSources;

  /// No description provided for @voiceGroundingPrivacyNote.
  ///
  /// In en, this message translates to:
  /// **'Only the topic and official links are checked. Your statement and profile stay on this device.'**
  String get voiceGroundingPrivacyNote;

  /// No description provided for @voiceCouldNotOpenSource.
  ///
  /// In en, this message translates to:
  /// **'Could not open the official source.'**
  String get voiceCouldNotOpenSource;

  /// No description provided for @voiceMatchStrong.
  ///
  /// In en, this message translates to:
  /// **'Strong match'**
  String get voiceMatchStrong;

  /// No description provided for @voiceMatchLikely.
  ///
  /// In en, this message translates to:
  /// **'Likely match'**
  String get voiceMatchLikely;

  /// No description provided for @voiceMatchNeedsConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Needs confirmation'**
  String get voiceMatchNeedsConfirmation;

  /// No description provided for @voiceMatchNotSuitable.
  ///
  /// In en, this message translates to:
  /// **'Not suitable'**
  String get voiceMatchNotSuitable;

  /// No description provided for @voiceMatchNoConfident.
  ///
  /// In en, this message translates to:
  /// **'No confident match'**
  String get voiceMatchNoConfident;

  /// No description provided for @voiceWhyThisFits.
  ///
  /// In en, this message translates to:
  /// **'Why this fits: {reasons}'**
  String voiceWhyThisFits(Object reasons);

  /// No description provided for @voiceStillConfirm.
  ///
  /// In en, this message translates to:
  /// **'Still confirm: {requirements}'**
  String voiceStillConfirm(Object requirements);

  /// No description provided for @voiceSourceVerified.
  ///
  /// In en, this message translates to:
  /// **'Current official source verified'**
  String get voiceSourceVerified;

  /// No description provided for @voiceSourceUnverified.
  ///
  /// In en, this message translates to:
  /// **'Uncertain or historical — verify before applying'**
  String get voiceSourceUnverified;

  /// No description provided for @voiceBestMatchingSchemes.
  ///
  /// In en, this message translates to:
  /// **'Best matching schemes'**
  String get voiceBestMatchingSchemes;

  /// No description provided for @voiceFactLabelState.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get voiceFactLabelState;

  /// No description provided for @voiceFactLabelSituation.
  ///
  /// In en, this message translates to:
  /// **'Situation'**
  String get voiceFactLabelSituation;

  /// No description provided for @voiceFactLabelMaritalStatus.
  ///
  /// In en, this message translates to:
  /// **'Marital status'**
  String get voiceFactLabelMaritalStatus;

  /// No description provided for @voiceFactLabelSector.
  ///
  /// In en, this message translates to:
  /// **'Sector'**
  String get voiceFactLabelSector;

  /// No description provided for @voiceFactLabelFundingNeed.
  ///
  /// In en, this message translates to:
  /// **'Funding need'**
  String get voiceFactLabelFundingNeed;

  /// No description provided for @voiceFactLabelLandholding.
  ///
  /// In en, this message translates to:
  /// **'Landholding'**
  String get voiceFactLabelLandholding;

  /// No description provided for @voiceFactConflictFormat.
  ///
  /// In en, this message translates to:
  /// **'{value} (profile: {conflictingValue})'**
  String voiceFactConflictFormat(Object conflictingValue, Object value);

  /// No description provided for @calcUdyamClassifierTitle.
  ///
  /// In en, this message translates to:
  /// **'Udyam MSME Classifier'**
  String get calcUdyamClassifierTitle;

  /// No description provided for @calcUdyamClassifierSub.
  ///
  /// In en, this message translates to:
  /// **'Classify your business under official government guidelines.'**
  String get calcUdyamClassifierSub;

  /// No description provided for @calcInvestmentLabel.
  ///
  /// In en, this message translates to:
  /// **'Investment in Plant & Machinery'**
  String get calcInvestmentLabel;

  /// No description provided for @calcInvestmentHelper.
  ///
  /// In en, this message translates to:
  /// **'Enter original purchase value of machinery in Crores'**
  String get calcInvestmentHelper;

  /// No description provided for @calcTurnoverLabel.
  ///
  /// In en, this message translates to:
  /// **'Annual Turnover'**
  String get calcTurnoverLabel;

  /// No description provided for @calcTurnoverHelper.
  ///
  /// In en, this message translates to:
  /// **'Enter total revenue/sales of last financial year in Crores'**
  String get calcTurnoverHelper;

  /// No description provided for @calcClassificationResult.
  ///
  /// In en, this message translates to:
  /// **'Classification Result'**
  String get calcClassificationResult;

  /// No description provided for @calcBtnCalculate.
  ///
  /// In en, this message translates to:
  /// **'Calculate Classification'**
  String get calcBtnCalculate;

  /// No description provided for @calcGstTitle.
  ///
  /// In en, this message translates to:
  /// **'GST / Tax Calculator'**
  String get calcGstTitle;

  /// No description provided for @calcGstSub.
  ///
  /// In en, this message translates to:
  /// **'Calculate CGST, SGST, and Total invoice amounts.'**
  String get calcGstSub;

  /// No description provided for @calcBaseAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Base Amount'**
  String get calcBaseAmountLabel;

  /// No description provided for @calcBaseAmountHelper.
  ///
  /// In en, this message translates to:
  /// **'Enter net value of goods or services before GST'**
  String get calcBaseAmountHelper;

  /// No description provided for @calcGstRateLabel.
  ///
  /// In en, this message translates to:
  /// **'GST Rate (%)'**
  String get calcGstRateLabel;

  /// No description provided for @calcBasePrice.
  ///
  /// In en, this message translates to:
  /// **'Base Price'**
  String get calcBasePrice;

  /// No description provided for @calcTotalInvoice.
  ///
  /// In en, this message translates to:
  /// **'Total Invoice'**
  String get calcTotalInvoice;

  /// No description provided for @calcBtnCalculateTax.
  ///
  /// In en, this message translates to:
  /// **'Calculate Tax'**
  String get calcBtnCalculateTax;

  /// No description provided for @calcEmiTitle.
  ///
  /// In en, this message translates to:
  /// **'Business Loan EMI Calculator'**
  String get calcEmiTitle;

  /// No description provided for @calcEmiSub.
  ///
  /// In en, this message translates to:
  /// **'Calculate monthly payments for your business loan.'**
  String get calcEmiSub;

  /// No description provided for @calcLoanAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Loan Amount'**
  String get calcLoanAmountLabel;

  /// No description provided for @calcLoanAmountHelper.
  ///
  /// In en, this message translates to:
  /// **'Enter total business loan sum required'**
  String get calcLoanAmountHelper;

  /// No description provided for @calcInterestRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Interest Rate (% p.a.)'**
  String get calcInterestRateLabel;

  /// No description provided for @calcTenureLabel.
  ///
  /// In en, this message translates to:
  /// **'Tenure (Months)'**
  String get calcTenureLabel;

  /// No description provided for @calcBtnCalculateEmi.
  ///
  /// In en, this message translates to:
  /// **'Calculate EMI'**
  String get calcBtnCalculateEmi;

  /// No description provided for @calcDpiitTitle.
  ///
  /// In en, this message translates to:
  /// **'DPIIT Recognition Checklist'**
  String get calcDpiitTitle;

  /// No description provided for @calcDpiitSub.
  ///
  /// In en, this message translates to:
  /// **'Evaluate if your business qualifies as a startup under DPIIT rules.'**
  String get calcDpiitSub;

  /// No description provided for @calcValuationTitle.
  ///
  /// In en, this message translates to:
  /// **'Seed Valuation Estimator'**
  String get calcValuationTitle;

  /// No description provided for @calcValuationSub.
  ///
  /// In en, this message translates to:
  /// **'Calculate estimated seed stage valuation ranges based on MRR and growth.'**
  String get calcValuationSub;

  /// No description provided for @calcDocChecklistTitle.
  ///
  /// In en, this message translates to:
  /// **'Business Setup Document Checklist'**
  String get calcDocChecklistTitle;

  /// No description provided for @calcDocChecklistSub.
  ///
  /// In en, this message translates to:
  /// **'Essential documents for registering and operating a business in India.'**
  String get calcDocChecklistSub;

  /// No description provided for @notifToastSelectedRead.
  ///
  /// In en, this message translates to:
  /// **'Selected notifications marked as read'**
  String get notifToastSelectedRead;

  /// No description provided for @notifToastSelectedDeleted.
  ///
  /// In en, this message translates to:
  /// **'Selected notifications deleted'**
  String get notifToastSelectedDeleted;

  /// No description provided for @notifToastAllRead.
  ///
  /// In en, this message translates to:
  /// **'All notifications marked as read'**
  String get notifToastAllRead;

  /// No description provided for @notifToastAllDeleted.
  ///
  /// In en, this message translates to:
  /// **'All notifications deleted'**
  String get notifToastAllDeleted;

  /// No description provided for @notifToastFilterOpened.
  ///
  /// In en, this message translates to:
  /// **'Filter options opened'**
  String get notifToastFilterOpened;

  /// No description provided for @retryVoice.
  ///
  /// In en, this message translates to:
  /// **'Retry voice'**
  String get retryVoice;
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
    'that was used.',
  );
}
