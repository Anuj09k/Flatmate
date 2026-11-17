import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Single source of truth for every configurable limit, day count, strike count,
/// compatibility weight, and fallback price (Section 18).
/// Can be overridden at runtime from the Supabase `config` table without a release.
class AppConfig {
  // Verification & Account Locks (Sections 7, 18)
  final int verificationWindowDays;
  final int unverifiedLockDays;
  final int minFaceCaptures;
  final List<String> faceScanDirections;
  final int maxVerificationAttemptsPerDay;
  final int verificationCooldownHours;
  final List<int> verificationReminderDays;

  // Weekly Swipes & Reset (Sections 10, 18)
  final int freeRightSwipesPerWeek;
  final int plusRightSwipesPerWeek;
  final int proRightSwipesPerWeek; // -1 represents unlimited
  final int weeklyResetWeekday; // DateTime.monday == 1
  final int weeklyResetHourIst;

  // Profile, Listing Photos & Prompts (Sections 6, 12, 18)
  final int minListerInteriorPhotos;
  final int minListerExteriorPhotos;
  final int minProfilePhotos;
  final int maxProfilePhotos;
  final int pHashDuplicateThreshold;
  final double maxPhotoLocationMismatchKm;
  final int promptsPerProfile;
  final int promptAnswerMaxChars;
  final int minAgeYears;

  // Safety, Contact Blocker & Strikes (Sections 10, 13, 18)
  final int superchatNoteMaxChars;
  final int chatEarlyMessageContactLockCount;
  final int strikeWarningMax;
  final List<int> suspensionDaysSchedule;
  final int strikeResetCleanDays;

  // Boosts, Superchats & Feed Ranking (Sections 9, 11, 18)
  final int boostDurationHours;
  final int boostStackBonusHours;
  final int freeBoostsPerWeek;
  final int plusBoostsPerWeek;
  final int proBoostsPerWeek;
  final int freeSuperchatsPerWeek;
  final int plusSuperchatsPerWeek;
  final int proSuperchatsPerWeek;
  final int newProfileLiftHours;
  final double newProfileLiftPoints;
  final double boostMaxLiftPoints;
  final double boostNeverBeatsScoreGap;

  // Compatibility Filter Weights (Section 9)
  final Map<String, double> compatibilityWeights;

  // Pricing & GST Fallbacks for Tests / Offline Display (Sections 11, 18)
  // Note: Live paywall displays store-reported RevenueCat Offerings first.
  final double gstRate;
  final Map<String, int> plusBasePricesInr;
  final Map<String, int> proBasePricesInr;

  const AppConfig({
    this.verificationWindowDays = 15,
    this.unverifiedLockDays = 75,
    this.minFaceCaptures = 2,
    this.faceScanDirections = const ['straight', 'left', 'right', 'up'],
    this.maxVerificationAttemptsPerDay = 3,
    this.verificationCooldownHours = 24,
    this.verificationReminderDays = const [1, 7, 12, 14, 15],
    this.freeRightSwipesPerWeek = 5,
    this.plusRightSwipesPerWeek = 25,
    this.proRightSwipesPerWeek = -1,
    this.weeklyResetWeekday = DateTime.monday,
    this.weeklyResetHourIst = 0,
    this.minListerInteriorPhotos = 2,
    this.minListerExteriorPhotos = 1,
    this.minProfilePhotos = 2,
    this.maxProfilePhotos = 6,
    this.pHashDuplicateThreshold = 8,
    this.maxPhotoLocationMismatchKm = 5.0,
    this.promptsPerProfile = 3,
    this.promptAnswerMaxChars = 150,
    this.minAgeYears = 18,
    this.superchatNoteMaxChars = 200,
    this.chatEarlyMessageContactLockCount = 5,
    this.strikeWarningMax = 3,
    this.suspensionDaysSchedule = const [3, 7, 30],
    this.strikeResetCleanDays = 90,
    this.boostDurationHours = 24,
    this.boostStackBonusHours = 12,
    this.freeBoostsPerWeek = 1,
    this.plusBoostsPerWeek = 2,
    this.proBoostsPerWeek = 3,
    this.freeSuperchatsPerWeek = 1,
    this.plusSuperchatsPerWeek = 5,
    this.proSuperchatsPerWeek = 10,
    this.newProfileLiftHours = 48,
    this.newProfileLiftPoints = 5.0,
    this.boostMaxLiftPoints = 12.0,
    this.boostNeverBeatsScoreGap = 15.0,
    this.compatibilityWeights = const {
      'budget_rent': 20.0,
      'smoking': 15.0,
      'sleep_time': 15.0,
      'cleaning': 12.0,
      'food_type': 10.0,
      'drinking': 8.0,
      'pets': 8.0,
      'maid_share': 5.0,
      'health_focus': 4.0,
      'social_style': 3.0,
    },
    this.gstRate = 0.18,
    this.plusBasePricesInr = const {
      'weekly': 109,
      'monthly_first_time': 149,
      'monthly': 329,
      '3_months': 829,
      '6_months': 1099,
      'yearly': 1399,
    },
    this.proBasePricesInr = const {
      'monthly_first_time': 249,
      'monthly': 479,
      '3_months': 1229,
      '6_months': 1599,
      'yearly': 1999,
    },
  });

  /// Fallback helper for tests & offline display: Base INR + 18% GST rounded to nearest rupee.
  int priceWithGst(int basePriceInr) => (basePriceInr * (1.0 + gstRate)).round();

  factory AppConfig.fromServerMap(Map<String, dynamic> map) {
    const defaults = AppConfig();
    return AppConfig(
      verificationWindowDays:
          (map['verification_window_days'] as num?)?.toInt() ?? defaults.verificationWindowDays,
      unverifiedLockDays:
          (map['unverified_lock_days'] as num?)?.toInt() ?? defaults.unverifiedLockDays,
      minFaceCaptures:
          (map['min_face_captures'] as num?)?.toInt() ?? defaults.minFaceCaptures,
      freeRightSwipesPerWeek:
          (map['free_right_swipes_per_week'] as num?)?.toInt() ?? defaults.freeRightSwipesPerWeek,
      plusRightSwipesPerWeek:
          (map['plus_right_swipes_per_week'] as num?)?.toInt() ?? defaults.plusRightSwipesPerWeek,
      proRightSwipesPerWeek:
          (map['pro_right_swipes_per_week'] as num?)?.toInt() ?? defaults.proRightSwipesPerWeek,
      minListerInteriorPhotos:
          (map['min_lister_interior_photos'] as num?)?.toInt() ?? defaults.minListerInteriorPhotos,
      minListerExteriorPhotos:
          (map['min_lister_exterior_photos'] as num?)?.toInt() ?? defaults.minListerExteriorPhotos,
      minProfilePhotos:
          (map['min_profile_photos'] as num?)?.toInt() ?? defaults.minProfilePhotos,
      maxProfilePhotos:
          (map['max_profile_photos'] as num?)?.toInt() ?? defaults.maxProfilePhotos,
      pHashDuplicateThreshold:
          (map['phash_duplicate_threshold'] as num?)?.toInt() ?? defaults.pHashDuplicateThreshold,
      maxPhotoLocationMismatchKm:
          (map['max_photo_location_mismatch_km'] as num?)?.toDouble() ??
              defaults.maxPhotoLocationMismatchKm,
      promptsPerProfile:
          (map['prompts_per_profile'] as num?)?.toInt() ?? defaults.promptsPerProfile,
      promptAnswerMaxChars:
          (map['prompt_answer_max_chars'] as num?)?.toInt() ?? defaults.promptAnswerMaxChars,
      minAgeYears: (map['min_age_years'] as num?)?.toInt() ?? defaults.minAgeYears,
      superchatNoteMaxChars:
          (map['superchat_note_max_chars'] as num?)?.toInt() ?? defaults.superchatNoteMaxChars,
      chatEarlyMessageContactLockCount:
          (map['chat_early_message_contact_lock_count'] as num?)?.toInt() ??
              defaults.chatEarlyMessageContactLockCount,
      strikeWarningMax:
          (map['strike_warning_max'] as num?)?.toInt() ?? defaults.strikeWarningMax,
      strikeResetCleanDays:
          (map['strike_reset_clean_days'] as num?)?.toInt() ?? defaults.strikeResetCleanDays,
      boostDurationHours:
          (map['boost_duration_hours'] as num?)?.toInt() ?? defaults.boostDurationHours,
      boostStackBonusHours:
          (map['boost_stack_bonus_hours'] as num?)?.toInt() ?? defaults.boostStackBonusHours,
    );
  }
}

final appConfigProvider = Provider<AppConfig>((ref) => const AppConfig());
