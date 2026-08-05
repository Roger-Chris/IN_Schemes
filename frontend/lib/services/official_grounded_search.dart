import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

enum GroundedSearchOutcome { found, noSources, offline }

@immutable
class GroundedSource {
  const GroundedSource({
    required this.title,
    required this.url,
    required this.snippet,
    required this.verifiedAt,
  });

  final String title;
  final Uri url;
  final String snippet;
  final DateTime verifiedAt;

  String get host => url.host;
}

@immutable
class GroundedSearchRequest {
  const GroundedSearchRequest({
    required this.topic,
    required this.sourceUrls,
    this.sourceLabels = const {},
  });

  /// A non-personal topic identifier produced by the local understanding
  /// engine. The raw user statement must never be supplied here.
  final String topic;
  final List<String> sourceUrls;
  final Map<String, String> sourceLabels;
}

@immutable
class GroundedSearchResult {
  const GroundedSearchResult({required this.outcome, this.sources = const []});

  final GroundedSearchOutcome outcome;
  final List<GroundedSource> sources;
}

abstract interface class OfficialGroundedSearch {
  Future<GroundedSearchResult> search(GroundedSearchRequest request);

  void close();
}

/// Retrieves evidence from official pages already selected by the trusted
/// local knowledge base or scheme catalog.
///
/// This deliberately does not scrape a general-purpose search engine. It
/// sends no transcript, profile fact, or free-form user text over the network.
class HttpOfficialGroundedSearch implements OfficialGroundedSearch {
  HttpOfficialGroundedSearch({
    http.Client? client,
    this.timeout = const Duration(seconds: 6),
    Set<String> additionalOfficialHosts = const {},
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null,
       _additionalOfficialHosts = {
         ..._defaultOfficialHosts,
         ...additionalOfficialHosts.map((host) => host.toLowerCase()),
       };

  final http.Client _client;
  final bool _ownsClient;
  final Duration timeout;
  final Set<String> _additionalOfficialHosts;
  final Map<String, _CachedGrounding> _cache = {};

  static const int _maximumPageBytes = 500 * 1024;
  static const Duration _cacheLifetime = Duration(minutes: 15);
  static const Set<String> _defaultOfficialHosts = {
    'cgtmse.in',
    'www.cgtmse.in',
    'startuptn.in',
    'www.startuptn.in',
    'catalyst.startuptn.in',
    'nseindia.com',
    'www.nseindia.com',
    'bseindia.com',
    'www.bseindia.com',
  };

  @override
  Future<GroundedSearchResult> search(GroundedSearchRequest request) async {
    final topic = _safeTopic(request.topic);
    final candidates = <Uri>[];
    for (final value in request.sourceUrls) {
      final uri = Uri.tryParse(value.trim());
      if (uri != null && isOfficialUri(uri) && !candidates.contains(uri)) {
        candidates.add(uri);
      }
      if (candidates.length == 3) break;
    }
    if (candidates.isEmpty) {
      return const GroundedSearchResult(
        outcome: GroundedSearchOutcome.noSources,
      );
    }

    final cacheKey = '$topic|${candidates.join('|')}';
    final cached = _cache[cacheKey];
    if (cached != null &&
        DateTime.now().difference(cached.createdAt) < _cacheLifetime) {
      return cached.result;
    }

    var networkFailed = false;
    final sources = <GroundedSource>[];
    await Future.wait(
      candidates.map((uri) async {
        try {
          final source = await _fetchSource(
            uri,
            topic: topic,
            fallbackLabel: request.sourceLabels[uri.toString()],
          );
          if (source != null) sources.add(source);
        } on TimeoutException {
          networkFailed = true;
        } on http.ClientException {
          networkFailed = true;
        } catch (_) {
          // A single malformed or blocked official page must not prevent other
          // official sources from grounding the response.
        }
      }),
    );

    sources.sort(
      (a, b) => candidates.indexOf(a.url).compareTo(candidates.indexOf(b.url)),
    );
    final result = GroundedSearchResult(
      outcome: sources.isNotEmpty
          ? GroundedSearchOutcome.found
          : networkFailed
          ? GroundedSearchOutcome.offline
          : GroundedSearchOutcome.noSources,
      sources: List.unmodifiable(sources),
    );
    if (sources.isNotEmpty) {
      _cache[cacheKey] = _CachedGrounding(DateTime.now(), result);
    }
    return result;
  }

  bool isOfficialUri(Uri uri) {
    if (uri.scheme != 'https' || uri.userInfo.isNotEmpty) return false;
    final host = uri.host.toLowerCase();
    if (host.isEmpty || Uri.parse('https://$host').host != host) return false;
    return host.endsWith('.gov.in') ||
        host.endsWith('.nic.in') ||
        _additionalOfficialHosts.contains(host);
  }

  Future<GroundedSource?> _fetchSource(
    Uri uri, {
    required String topic,
    String? fallbackLabel,
  }) async {
    final request = http.Request('GET', uri)
      ..headers.addAll(const {
        'Accept': 'text/html,application/xhtml+xml,text/plain;q=0.9',
        'User-Agent': 'NammaThittam/1.0 official-source-verifier',
      });
    final response = await _client.send(request).timeout(timeout);
    final finalUri = response.request?.url ?? uri;
    if (response.statusCode != 200 || !isOfficialUri(finalUri)) return null;
    final contentType = response.headers['content-type']?.toLowerCase() ?? '';
    if (contentType.isNotEmpty &&
        !contentType.contains('text/html') &&
        !contentType.contains('application/xhtml+xml') &&
        !contentType.contains('text/plain')) {
      return null;
    }
    final declaredLength = response.contentLength;
    if (declaredLength != null && declaredLength > _maximumPageBytes) {
      return null;
    }
    final bytes = await _readLimited(response.stream).timeout(timeout);
    if (bytes == null) return null;
    final html = utf8.decode(bytes, allowMalformed: true);
    final title = _extractTitle(html, fallbackLabel, finalUri.host);
    final snippet = _extractSnippet(html, topic);
    if (snippet.isEmpty) return null;
    return GroundedSource(
      title: title,
      url: finalUri,
      snippet: snippet,
      verifiedAt: DateTime.now(),
    );
  }

  static String _safeTopic(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z_\- ]'), ' ')
        .replaceAll(RegExp(r'[_\-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .split(' ')
        .where((word) => word.length > 2)
        .take(8)
        .join(' ');
  }

  static String _extractTitle(String html, String? fallbackLabel, String host) {
    final match = RegExp(
      r'<title\b[^>]*>([\s\S]*?)</title>',
      caseSensitive: false,
    ).firstMatch(html);
    final title = _cleanText(match?.group(1) ?? '');
    if (title.isNotEmpty) return _shorten(title, 120);
    final fallback = _cleanText(fallbackLabel ?? '');
    return fallback.isNotEmpty ? fallback : host;
  }

  static String _extractSnippet(String html, String topic) {
    final withoutNoise = html
        .replaceAll(
          RegExp(
            r'<(script|style|noscript)\b[^>]*>[\s\S]*?</\1>',
            caseSensitive: false,
          ),
          ' ',
        )
        .replaceAll(RegExp(r'<!--([\s\S]*?)-->'), ' ');
    String? meta;
    for (final tag in RegExp(
      r'<meta\b[^>]*>',
      caseSensitive: false,
    ).allMatches(withoutNoise)) {
      final value = tag.group(0) ?? '';
      final lower = value.toLowerCase();
      if (!lower.contains('description')) continue;
      meta =
          RegExp(
            r'''content\s*=\s*["']([^"']+)["']''',
            caseSensitive: false,
          ).firstMatch(value)?.group(1) ??
          meta;
      if (meta != null) break;
    }
    final blocks = RegExp(
      r'<(?:p|li|h1|h2|h3)\b[^>]*>([\s\S]*?)</(?:p|li|h1|h2|h3)>',
      caseSensitive: false,
    ).allMatches(withoutNoise).map((match) => _cleanText(match.group(1) ?? ''));
    final terms = topic.split(' ').where((term) => term.length > 2).toSet();
    final ranked =
        blocks
            .where((text) => text.length >= 45)
            .map(
              (text) => MapEntry(
                text,
                terms.where((term) => text.toLowerCase().contains(term)).length,
              ),
            )
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    final best = ranked.isNotEmpty ? ranked.first.key : '';
    final description = _cleanText(meta ?? '');
    return _shorten(best.isNotEmpty ? best : description, 340);
  }

  static String _cleanText(String value) {
    return value
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String _shorten(String value, int maximum) {
    if (value.length <= maximum) return value;
    final cut = value.substring(0, maximum - 1);
    final lastSpace = cut.lastIndexOf(' ');
    return '${cut.substring(0, lastSpace > maximum ~/ 2 ? lastSpace : cut.length)}…';
  }

  static Future<Uint8List?> _readLimited(Stream<List<int>> stream) async {
    final bytes = BytesBuilder(copy: false);
    await for (final chunk in stream) {
      if (bytes.length + chunk.length > _maximumPageBytes) return null;
      bytes.add(chunk);
    }
    return bytes.takeBytes();
  }

  @override
  void close() {
    if (_ownsClient) _client.close();
    _cache.clear();
  }
}

class _CachedGrounding {
  const _CachedGrounding(this.createdAt, this.result);

  final DateTime createdAt;
  final GroundedSearchResult result;
}
