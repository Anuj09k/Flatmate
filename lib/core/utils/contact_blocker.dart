/// Client-side live nudge & pre-flight validator matching the server-side
/// `contains_contact_details` SQL function (Section 13).
class ContactBlocker {
  static final Map<String, String> _spelledWords = {
    r'\b(zero|oh)\b': '0',
    r'\b(one|ek)\b': '1',
    r'\b(two|do)\b': '2',
    r'\b(three|teen)\b': '3',
    r'\b(four|char)\b': '4',
    r'\b(five|paanch)\b': '5',
    r'\b(six|cheh)\b': '6',
    r'\b(seven|saat)\b': '7',
    r'\b(eight|aath)\b': '8',
    r'\b(nine|nau)\b': '9',
  };

  static final RegExp _emailRegex =
      RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}', caseSensitive: false);

  static final RegExp _socialOrHandleRegex = RegExp(
    r'(\b(instagram|insta|ig|snapchat|snap|telegram|tg|whatsapp|wa\.me|t\.me|linkedin|facebook|fb)\b|\bdm\s+me\b|\btext\s+me\s+on\b|\bhmu\s+on\b|\bping\s+me\s+on\b|@[a-zA-Z0-9_.]{3,})',
    caseSensitive: false,
  );

  /// Returns true if [text] contains phone numbers (spaced, spelled-out, or mixed
  /// with emojis/symbols), social handles, links, or emails.
  static bool containsContactDetails(String text) {
    if (text.trim().isEmpty) return false;

    var normalized = text.toLowerCase();
    if (_emailRegex.hasMatch(normalized) || _socialOrHandleRegex.hasMatch(normalized)) {
      return true;
    }

    _spelledWords.forEach((pattern, digit) {
      normalized = normalized.replaceAll(RegExp(pattern, caseSensitive: false), digit);
    });

    final digitsOnly = normalized.replaceAll(RegExp(r'[^0-9]'), '');
    return digitsOnly.length >= 7;
  }
}
