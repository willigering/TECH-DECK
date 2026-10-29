import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Hosts the updater may talk to. Release assets redirect from github.com to
/// GitHub's asset CDN; anything else is rejected.
const Set<String> kTrustedUpdateHosts = {
  'api.github.com',
  'github.com',
  'objects.githubusercontent.com',
  'release-assets.githubusercontent.com',
};

bool isTrustedUpdateUri(Uri uri) =>
    uri.scheme == 'https' &&
    kTrustedUpdateHosts.contains(uri.host.toLowerCase()) &&
    (!uri.hasPort || uri.port == 443) &&
    uri.userInfo.isEmpty;

class HttpTextResponse {
  const HttpTextResponse(this.statusCode, this.body, this.headers);
  final int statusCode;
  final String body;
  final Map<String, String> headers;
}

class HttpStreamResponse {
  const HttpStreamResponse(this.statusCode, this.contentLength, this.stream);
  final int statusCode;
  final int contentLength;
  final Stream<List<int>> stream;
}

/// Minimal transport so tests can replace the network completely.
abstract class UpdateHttp {
  Future<HttpTextResponse> getText(
    Uri uri, {
    Map<String, String> headers = const {},
    int maxBytes = 512 * 1024,
  });

  Future<HttpStreamResponse> getStream(Uri uri);

  void cancelAll() {}
}

/// dart:io implementation: HTTPS only, manual redirects restricted to trusted
/// hosts, strict timeouts, bounded response sizes.
class IoUpdateHttp implements UpdateHttp {
  IoUpdateHttp({HttpClient? client})
    : _client =
          client ??
          (HttpClient()
            ..connectionTimeout = const Duration(seconds: 15)
            ..idleTimeout = const Duration(seconds: 15)
            ..userAgent = 'TECH-DECK-Updater');

  final HttpClient _client;
  static const _timeout = Duration(seconds: 20);

  Future<HttpClientResponse> _open(Uri uri, Map<String, String> headers) async {
    var current = uri;
    for (var hop = 0; hop < 5; hop++) {
      if (!isTrustedUpdateUri(current)) {
        throw HttpException('Untrusted update URL', uri: current);
      }
      final req = await _client.getUrl(current).timeout(_timeout);
      req.followRedirects = false;
      headers.forEach(req.headers.set);
      final res = await req.close().timeout(_timeout);
      if (res.isRedirect) {
        final loc = res.headers.value(HttpHeaders.locationHeader);
        await res.drain<void>();
        if (loc == null) throw HttpException('Redirect without location');
        current = current.resolve(loc);
        continue;
      }
      return res;
    }
    throw HttpException('Too many redirects', uri: uri);
  }

  @override
  Future<HttpTextResponse> getText(
    Uri uri, {
    Map<String, String> headers = const {},
    int maxBytes = 512 * 1024,
  }) async {
    final res = await _open(uri, headers);
    final bytes = <int>[];
    await for (final chunk in res.timeout(_timeout)) {
      bytes.addAll(chunk);
      if (bytes.length > maxBytes) {
        throw const HttpException('Response too large');
      }
    }
    final h = <String, String>{};
    res.headers.forEach((k, v) => h[k.toLowerCase()] = v.join(','));
    return HttpTextResponse(
      res.statusCode,
      utf8.decode(bytes, allowMalformed: true),
      h,
    );
  }

  @override
  Future<HttpStreamResponse> getStream(Uri uri) async {
    final res = await _open(uri, const {'Accept': 'application/octet-stream'});
    return HttpStreamResponse(
      res.statusCode,
      res.contentLength,
      res.timeout(const Duration(seconds: 30)),
    );
  }

  @override
  void cancelAll() => _client.close(force: true);
}
