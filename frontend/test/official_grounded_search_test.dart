import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/official_grounded_search.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'fetches extractive evidence only from an official HTTPS page',
    () async {
      late http.Request sentRequest;
      final client = MockClient((request) async {
        sentRequest = request;
        return http.Response(
          '''
        <html>
          <head><title>Official MSME Support</title></head>
          <body>
            <script>Ignore this private text.</script>
            <p>Collateral-free credit support is available for eligible micro
            and small enterprises under the published guarantee framework.</p>
          </body>
        </html>
        ''',
          200,
          headers: {'content-type': 'text/html; charset=utf-8'},
        );
      });
      final search = HttpOfficialGroundedSearch(client: client);

      final result = await search.search(
        const GroundedSearchRequest(
          topic: 'collateral_free_loan income 250000 phone 9999999999',
          sourceUrls: ['https://msme.gov.in/credit-support'],
        ),
      );

      expect(result.outcome, GroundedSearchOutcome.found);
      expect(result.sources.single.title, 'Official MSME Support');
      expect(result.sources.single.snippet, contains('Collateral-free credit'));
      expect(result.sources.single.snippet, isNot(contains('private text')));
      expect(sentRequest.url.toString(), 'https://msme.gov.in/credit-support');
      expect(sentRequest.url.query, isEmpty);
      expect(sentRequest.body, isEmpty);
      search.close();
    },
  );

  test('blocks non-official, insecure, and credential-bearing URLs', () async {
    var calls = 0;
    final search = HttpOfficialGroundedSearch(
      client: MockClient((_) async {
        calls++;
        return http.Response('should not be requested', 200);
      }),
    );

    final result = await search.search(
      const GroundedSearchRequest(
        topic: 'startup funding',
        sourceUrls: [
          'https://attacker.example/startup',
          'http://msme.gov.in/insecure',
          'https://user:password@msme.gov.in/private',
        ],
      ),
    );

    expect(result.outcome, GroundedSearchOutcome.noSources);
    expect(calls, 0);
  });

  test('reports offline without replacing the local answer', () async {
    final search = HttpOfficialGroundedSearch(
      client: MockClient((request) async {
        throw http.ClientException('network unreachable', request.url);
      }),
    );

    final result = await search.search(
      const GroundedSearchRequest(
        topic: 'student scholarship',
        sourceUrls: ['https://www.tn.gov.in/scheme'],
      ),
    );

    expect(result.outcome, GroundedSearchOutcome.offline);
    expect(result.sources, isEmpty);
  });

  test('allows explicitly curated authoritative non-government hosts', () {
    final search = HttpOfficialGroundedSearch(
      client: MockClient((_) async => http.Response('', 404)),
    );

    expect(
      search.isOfficialUri(Uri.parse('https://startuptn.in/funding')),
      isTrue,
    );
    expect(search.isOfficialUri(Uri.parse('https://www.cgtmse.in/')), isTrue);
    expect(
      search.isOfficialUri(Uri.parse('https://fake-startuptn.in/')),
      isFalse,
    );
  });
}
