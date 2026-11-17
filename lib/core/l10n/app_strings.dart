/// Centralised user-facing strings (Section 5: Launch in English, add Hindi next).
class AppStrings {
  final String locale;
  const AppStrings({this.locale = 'en'});

  static const Map<String, Map<String, String>> _translations = {
    'en': {
      'app_title': 'Flatmate App',
      'tagline': 'A verified, swipe-based app for finding flatmates. Not a dating app.',
      'step_chat_title': 'CHAT',
      'step_chat_sub': 'Vibe check first',
      'step_verify_title': 'VERIFY IDS',
      'step_verify_sub': 'Know who is real',
      'step_meet_title': 'MEET FIRST',
      'step_meet_sub': 'Before moving in',
      'step_compatible_title': 'COMPATIBLE?',
      'step_compatible_sub': 'Then decide',
      'get_started': 'Get Started',
      'phone_title': 'Sign in with your phone',
      'phone_subtitle': 'We will send a 6-digit OTP to verify your number.',
      'phone_label': 'Mobile number (+91)',
      'email_label': 'Email (optional)',
      'dob_label': 'Date of birth (Must be 18+)',
      'send_otp': 'Send OTP',
      'verify_otp': 'Verify & Continue',
      'choose_role_title': 'How are you using Flatmate App?',
      'role_lister_title': 'I have a flat',
      'role_lister_sub': 'Show your flat honestly with photos, rent, and house rules.',
      'role_seeker_title': 'I am looking for a place',
      'role_seeker_sub': 'Create a verified profile with your budget, area, and habits.',
      'profile_setup_title': 'Build your profile',
      'prompts_setup_title': 'Pick 3 profile prompts',
      'listing_setup_title': 'Your flat details & photos',
      'flat_photo_rule_banner':
          'Required: At least 2 non-duplicate interior photos (different rooms/angles) and 1 exterior building/entrance photo.',
      'flat_photos_verified_badge': 'Flat photos verified',
      'looking_for_place_badge': 'Looking for a place',
      'contact_nudge': 'Contact details are not allowed here.',
      'publish_profile': 'Save & Continue',
    },
    'hi': {
      'app_title': 'Flatmate App',
      'contact_nudge': 'यहाँ फ़ोन नंबर या सोशल हैंडल लिखना मना है।',
    },
  };

  String tr(String key) => _translations[locale]?[key] ?? _translations['en']![key] ?? key;
}
