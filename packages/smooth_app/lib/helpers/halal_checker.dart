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
HalalResult checkHalal({
  String? ingredientsText,
  List<String>? additiveNames,
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
    if (_hasKeyword(text, rule.term)) {
      add(rule.term, rule.reason, HalalVerdict.mushbooh);
    }
  }
  for (final HalalRule rule in HALAL_MUSHBOOH_E_NUMBERS) {
    if (codes.contains(rule.term)) {
      add(rule.term, rule.reason, HalalVerdict.mushbooh);
    }
  }

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
List<int> _keywordPositions(String text, String term) {
  final RegExp regExp = RegExp(
    '(?<![a-z])${RegExp.escape(term)}(?![a-z])',
  );
  final List<int> positions = <int>[];
  for (final RegExpMatch match in regExp.allMatches(text)) {
    if (_isHarmlessContext(text, term, match)) {
      continue;
    }
    positions.add(match.start);
  }
  return positions;
}

bool _hasKeyword(String text, String term) =>
    _keywordPositions(text, term).isNotEmpty;

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
