import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Remembers when each barcode was last scanned/opened, for the History list.
class ScanTimes {
  const ScanTimes._();

  static const String _KEY = 'halalpal_scan_times';
  static final Map<String, int> _times = <String, int>{};
  static final ValueNotifier<int> changes = ValueNotifier<int>(0);
  static bool _loaded = false;

  static Future<void> _load() async {
    if (_loaded) {
      return;
    }
    _loaded = true;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(_KEY);
      if (raw != null) {
        final Map<String, dynamic> decoded =
            jsonDecode(raw) as Map<String, dynamic>;
        decoded.forEach((String k, dynamic v) {
          _times.putIfAbsent(k, () => v as int);
        });
        changes.value++;
      }
    } catch (_) {
      // History times are cosmetic: never fail because of them.
    }
  }

  static Future<void> init() => _load();

  static Future<void> record(String barcode) async {
    await _load();
    _times[barcode] = DateTime.now().millisecondsSinceEpoch;
    changes.value++;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_KEY, jsonEncode(_times));
    } catch (_) {}
  }

  static DateTime? of(String barcode) {
    final int? ms = _times[barcode];
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  /// "just now", "5 min ago", "2 h ago", "3 d ago"…
  static String ago(DateTime? time) {
    if (time == null) {
      return '';
    }
    final Duration d = DateTime.now().difference(time);
    if (d.inMinutes < 1) {
      return 'just now';
    }
    if (d.inMinutes < 60) {
      return '${d.inMinutes} min ago';
    }
    if (d.inHours < 24) {
      return '${d.inHours} h ago';
    }
    if (d.inDays < 30) {
      return '${d.inDays} d ago';
    }
    return '${(d.inDays / 30).floor()} mo ago';
  }
}
