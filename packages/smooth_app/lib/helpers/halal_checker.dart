import 'package:smooth_app/helpers/halal_rules.dart';

/// Result of a halal check, from worst to best.
enum HalalVerdict {
  /// At least one ingredient is haram.
  haram,

  /// No haram ingredient, but at least one depends on its source.
  mushbooh,

  /// Ingredients were checked and nothing was flagged.
  /// This is NOT a halal certification.
  clear,

  /// There is no ingredient information to check.
  unknown,
}

class HalalFinding {
  const HalalFinding({
    required this.term,
    required this.reason,
    required this.verdict,
  });

  final String term;
  final String reason;
  final HalalVerdict verdict;
}

class HalalResult {
  const HalalResult({required this.verdict, required this.findings});

  final HalalVerdict verdict;
  final List<HalalFinding> findings;
}

/// Deterministic halal check: the same input always gives the same verdict,
/// and a haram match can never be overridden.
///
/// [halalCertified] is true when the product's labels say it is halal
/// certified: then only the things that are never allowed (pork, alcohol,
/// blood, carmine) are flagged, not the source-dependent ones.
HalalResult checkHalal({
  String? ingredientsText,
  List<String>? additiveNames,
  bool halalCertified = false,
}) {
  final String text = <String>[
    if (ingredientsText != null) ingredientsText,
    if (additiveNames != null) ...additiveNames,
  ].join('\n').toLowerCase().trim();

  if (text.isEmpty) {
    return const HalalResult(
      verdict: HalalVerdict.unknown,
      findings: <HalalFinding>[],
    );
  }

  final Map<String, HalalFinding> found = <String, HalalFinding>{};

  void add(String term, String reason, HalalVerdict verdict) {
    final String key = term.toLowerCase();
    final HalalFinding? existing = found[key];
    // Never downgrade a haram finding.
    if (existing != null && existing.verdict == HalalVerdict.haram) {
      return;
    }
    found[key] = HalalFinding(term: term, reason: reason, verdict: verdict);
  }

  // 1. Haram keywords.
  for (final HalalRule rule in HALAL_HARAM_KEYWORDS) {
    if (_hasKeyword(text, rule.term)) {
      add(rule.term, rule.reason, HalalVerdict.haram);
    }
  }

  // 2. E-numbers found in the text.
  final Set<String> codes = _extractENumbers(text);
  for (final HalalRule rule in HALAL_HARAM_E_NUMBERS) {
    if (codes.contains(rule.term)) {
      add(rule.term, rule.reason, HalalVerdict.haram);
    }
  }

  if (halalCertified) {
    return _finish(found);
  }

  // 3. Gelatin: haram unless the source is stated.
  final List<int> gelatinPositions = <int>[
    for (final String term in HALAL_GELATIN_TERMS)
      ..._keywordPositions(text, term),
  ];
  final bool hasGelatinCode = codes.contains(HALAL_GELATIN_E_NUMBER);
  if (gelatinPositions.isNotEmpty || hasGelatinCode) {
    bool sourceStated = gelatinPositions.isNotEmpty;
    for (final int position in gelatinPositions) {
      final String window = text.substring(
        position - 30 < 0 ? 0 : position - 30,
        position + 40 > text.length ? text.length : position + 40,
      );
      if (!HALAL_GELATIN_SOURCE_WORDS.any(window.contains)) {
        sourceStated = false;
        break;
      }
    }
    if (hasGelatinCode && gelatinPositions.isEmpty) {
      sourceStated = false;
    }
    if (sourceStated) {
      add(
        'gelatin',
        'Source is stated, but check it is halal certified',
        HalalVerdict.mushbooh,
      );
    } else {
      add(
        'gelatin',
        'Gelatin with no stated source (often pork)',
        HalalVerdict.haram,
      );
    }
  }

  // 4. Doubtful (mushbooh) keywords and E-numbers.
  for (final HalalRule rule in HALAL_MUSHBOOH_KEYWORDS) {
    final bool plainFlavour = rule.reason == HALAL_FLAVOURING_REASON;
    if (plainFlavour &&
        found.keys.any((String k) => k.startsWith('natural flavo'))) {
      // "natural flavouring" is already listed; do not list it twice.
      continue;
    }
    if (_hasKeyword(text, rule.term, exemptions: HALAL_SOURCE_EXEMPTIONS)) {
      add(rule.term, rule.reason, HalalVerdict.mushbooh);
    }
  }
  for (final HalalRule rule in HALAL_MUSHBOOH_E_NUMBERS) {
    if (codes.contains(rule.term)) {
      add(rule.term, rule.reason, HalalVerdict.mushbooh);
    }
  }

  return _finish(found);
}

/// True if the product's label tags say it is halal certified.
bool isHalalCertifiedByLabels(List<String>? labelsTags) =>
    labelsTags?.any((String tag) {
      final String t = tag.toLowerCase();
      return t.contains('halal') &&
          !t.contains('non-halal') &&
          !t.contains('not-halal') &&
          !t.contains('no-halal');
    }) ??
    false;

HalalResult _finish(Map<String, HalalFinding> found) {
  final List<HalalFinding> findings = found.values.toList(growable: false);
  // Haram first, then mushbooh.
  findings.sort(
    (HalalFinding a, HalalFinding b) =>
        a.verdict.index.compareTo(b.verdict.index),
  );

  HalalVerdict verdict = HalalVerdict.clear;
  if (findings.any((HalalFinding f) => f.verdict == HalalVerdict.haram)) {
    verdict = HalalVerdict.haram;
  } else if (findings.isNotEmpty) {
    verdict = HalalVerdict.mushbooh;
  }
  return HalalResult(verdict: verdict, findings: findings);
}

/// Start positions of [term] as a whole word in [text], ignoring harmless
/// phrases such as "alcohol free" or "wine vinegar".
List<int> _keywordPositions(
  String text,
  String term, {
  Map<String, List<String>>? exemptions,
}) {
  final RegExp regExp = RegExp(
    '(?<![a-z])${RegExp.escape(term)}(?![a-z])',
  );
  final List<String>? sourceWords = exemptions?[term];
  final List<int> positions = <int>[];
  for (final RegExpMatch match in regExp.allMatches(text)) {
    if (_isHarmlessContext(text, term, match)) {
      continue;
    }
    if (sourceWords != null && _sourceStatedNear(text, match, sourceWords)) {
      continue;
    }
    positions.add(match.start);
  }
  return positions;
}

bool _hasKeyword(
  String text,
  String term, {
  Map<String, List<String>>? exemptions,
}) => _keywordPositions(text, term, exemptions: exemptions).isNotEmpty;

/// True if a source word is written right next to the match, such as
/// "microbial rennet" or "lecithin (soya)". Words must touch the term (before
/// it, or in brackets after it), so "glycerin, palm oil" is still flagged.
/// Halal wording ("halal chicken", "chicken (halal)", "alcohol free flavour")
/// is also accepted a few words either side.
bool _sourceStatedNear(String text, RegExpMatch match, List<String> words) {
  final String before = text.substring(0, match.start);
  final String after = text.substring(match.end);
  if (words.contains('halal')) {
    final String window =
        before.substring(before.length > 30 ? before.length - 30 : 0) +
        after.substring(0, after.length > 30 ? 30 : after.length);
    return words.any(window.contains);
  }
  for (final String word in words) {
    final String w = RegExp.escape(word);
    if (RegExp('(?<![a-z])$w[a-z]*[\\s-]*\$').hasMatch(before)) {
      return true;
    }
    if (RegExp('^\\s*[(\\[:,/-]\\s*$w').hasMatch(after) &&
        !RegExp(r'^\s*,').hasMatch(after)) {
      return true;
    }
  }
  return false;
}

bool _isHarmlessContext(String text, String term, RegExpMatch match) {
  final String before = text.substring(0, match.start);
  final String after = text.substring(match.end);
  if (term == 'alcohol') {
    if (RegExp(r'^[\s-]*free').hasMatch(after)) {
      return true;
    }
    if (RegExp(r'non[\s-]*$').hasMatch(before)) {
      return true;
    }
  }
  if (term == 'wine' && RegExp(r'^\s*vinegar').hasMatch(after)) {
    return true;
  }
  if (term == 'blood' && RegExp(r'^\s*orange').hasMatch(after)) {
    return true;
  }
  if (term == 'meat' &&
      (RegExp(r'^[\s-]*free').hasMatch(after) ||
          RegExp(r'(no|non|not)[\s-]*$').hasMatch(before))) {
    return true;
  }
  if (term == 'flavour' || term == 'flavor') {
    // "flavour enhancer" (for example E621) is an additive, not a flavouring.
    if (RegExp(r'^\s*enhancer').hasMatch(after)) {
      return true;
    }
  }
  if (<String>{
        'chicken', 'beef', 'lamb', 'turkey', 'duck', 'veal', 'goat', 'meat',
      }.contains(term) &&
      RegExp(r'^\s*(flavou?r|flavou?red|style|seasoning|taste)').hasMatch(after)) {
    return true;
  }
  if (term == 'goat' &&
      RegExp(r"^(['’]s)?\s*(milk|cheese|cheeses|curd|yogh?urt)").hasMatch(after)) {
    return true;
  }
  if (term == 'lamb' && RegExp(r"^(['’]s)?\s*lettuce").hasMatch(after)) {
    return true;
  }
  if (term == 'beef' && RegExp(r'^\s*tomato').hasMatch(after)) {
    return true;
  }
  return false;
}

/// E-numbers such as "e471", "e 471", "e-472a" found in [text], returned as
/// upper-case codes ("E471", "E472A").
Set<String> _extractENumbers(String text) {
  final RegExp regExp = RegExp(
    r'(?<![a-z0-9])e[\s-]?(\d{3,4})([a-z]?)(?![a-z0-9])',
  );
  return <String>{
    for (final RegExpMatch match in regExp.allMatches(text))
      'E${match.group(1)}${match.group(2)!.toUpperCase()}',
  };
}
