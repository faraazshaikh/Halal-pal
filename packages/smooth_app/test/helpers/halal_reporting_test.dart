import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smooth_app/helpers/halal_reporting.dart';

void main() {
  late List<http.Request> sent;

  void setUpReporting({required bool crash, required bool usage}) {
    sent = <http.Request>[];
    HalalReporting.configure(
      crash: crash,
      usage: usage,
      version: '1.1.0+9',
      url: Uri.parse('https://example.test/hook'),
      sendInDebug: true,
      clientFactory: () => MockClient((http.Request request) async {
        sent.add(request);
        return http.Response('ok', 200);
      }),
    );
  }

  group('crash reports', () {
    test('are sent when the switch is on, with no email address in them', () async {
      setUpReporting(crash: true, usage: false);
      await HalalReporting.reportCrash(
        StateError('boom'),
        StackTrace.fromString('#0 main'),
      );
      expect(sent, hasLength(1));
      expect(sent.single.url.toString(), 'https://example.test/hook');
      final Map<String, dynamic> body =
          jsonDecode(sent.single.body) as Map<String, dynamic>;
      expect(body['kind'], 'crash');
      expect(body['app'], '1.1.0+9');
      expect(body['error'], contains('boom'));
      expect(sent.single.body, isNot(contains('@')));
    });

    test('are not sent when the switch is off', () async {
      setUpReporting(crash: false, usage: true);
      await HalalReporting.reportCrash(StateError('boom'), null);
      expect(sent, isEmpty);
    });

    test('the same error is sent once and at most five are sent', () async {
      setUpReporting(crash: true, usage: false);
      await HalalReporting.reportCrash(StateError('same'), null);
      await HalalReporting.reportCrash(StateError('same'), null);
      expect(sent, hasLength(1));
      for (int i = 0; i < 10; i++) {
        await HalalReporting.reportCrash(StateError('different $i'), null);
      }
      expect(sent, hasLength(5));
    });

    test('a failing server never throws', () async {
      HalalReporting.configure(
        crash: true,
        usage: false,
        sendInDebug: true,
        clientFactory: () =>
            MockClient((http.Request request) async => throw Exception('down')),
      );
      await HalalReporting.reportCrash(StateError('boom'), null);
    });
  });

  group('usage', () {
    test('is queued and sent on flush when the switch is on', () async {
      setUpReporting(crash: false, usage: true);
      HalalReporting.trackUsage('tab', <String, String>{'name': 'history'});
      HalalReporting.trackVerdict('123', 'mushbooh');
      HalalReporting.trackVerdict('123', 'mushbooh');
      await HalalReporting.flush();
      expect(sent, hasLength(1));
      final Map<String, dynamic> body =
          jsonDecode(sent.single.body) as Map<String, dynamic>;
      expect(body['kind'], 'usage');
      expect((body['events'] as List<dynamic>), hasLength(2));
      expect(sent.single.body, isNot(contains('123')));
    });

    test('is dropped when the switch is off', () async {
      setUpReporting(crash: true, usage: false);
      HalalReporting.trackUsage('tab');
      await HalalReporting.flush();
      expect(sent, isEmpty);
    });
  });
}
