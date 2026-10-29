import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';

import 'update_http.dart';
import 'update_models.dart';

class CancelToken {
  bool _cancelled = false;
  final _listeners = <void Function()>[];
  bool get isCancelled => _cancelled;
  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    for (final l in _listeners) {
      l();
    }
  }

  void onCancel(void Function() l) {
    if (_cancelled) {
      l();
    } else {
      _listeners.add(l);
    }
  }
}

typedef ProgressCallback = void Function(int received, int total);

/// Streams an APK into app-private storage, verifying size and SHA-256.
/// Partial files are always removed on failure or cancellation.
class ApkDownloader {
  ApkDownloader(this.http);
  final UpdateHttp http;

  Future<File> download({
    required UpdateApk apk,
    required Directory dir,
    required int freeBytes,
    ProgressCallback? onProgress,
    CancelToken? cancel,
  }) async {
    if (!isTrustedUpdateUri(apk.url)) {
      throw const UpdateException(
        'Download-Quelle ist nicht vertrauenswürdig.',
      );
    }
    if (apk.size <= 0 || apk.size > 300 * 1024 * 1024) {
      throw const UpdateException('Unplausible APK-Größe.');
    }
    // Need room for the file plus Android's copy during installation.
    if (freeBytes < apk.size * 2 + 20 * 1024 * 1024) {
      throw const UpdateException('Nicht genügend freier Speicherplatz.');
    }
    await dir.create(recursive: true);
    await cleanup(dir);
    final safeName = apk.name.replaceAll(RegExp(r'[^A-Za-z0-9._+-]'), '_');
    final part = File('${dir.path}/$safeName.part');
    final target = File('${dir.path}/$safeName');
    IOSink? sink;
    StreamSubscription<List<int>>? sub;
    try {
      final res = await http.getStream(apk.url);
      if (res.statusCode != 200) {
        throw UpdateException(
          'Download fehlgeschlagen (HTTP ${res.statusCode}).',
        );
      }
      if (res.contentLength >= 0 && res.contentLength != apk.size) {
        throw const UpdateException(
          'Dateigröße auf dem Server passt nicht zu den Metadaten.',
        );
      }
      sink = part.openWrite();
      final digestSink = _DigestSink();
      final hasher = sha256.startChunkedConversion(digestSink);
      var received = 0;
      final done = Completer<void>();
      sub = res.stream.listen(
        (chunk) {
          received += chunk.length;
          if (received > apk.size) {
            done.completeError(
              const UpdateException('Download größer als erwartet.'),
            );
            return;
          }
          hasher.add(chunk);
          sink!.add(chunk);
          onProgress?.call(received, apk.size);
        },
        onError: (Object e) {
          if (!done.isCompleted) done.completeError(e);
        },
        onDone: () {
          if (!done.isCompleted) done.complete();
        },
        cancelOnError: true,
      );
      cancel?.onCancel(() {
        if (!done.isCompleted) {
          done.completeError(const UpdateException('Download abgebrochen.'));
        }
      });
      await done.future;
      await sub.cancel();
      sub = null;
      await sink.flush();
      await sink.close();
      sink = null;
      if (received != apk.size) {
        throw const UpdateException('Download unvollständig.');
      }
      hasher.close();
      if (digestSink.value.toString() != apk.sha256.toLowerCase()) {
        throw const UpdateException(
          'SHA-256-Prüfsumme stimmt nicht. APK ist beschädigt oder manipuliert.',
        );
      }
      return await part.rename(target.path);
    } on UpdateException {
      await _discard(sub, sink, part, target);
      rethrow;
    } catch (e) {
      await _discard(sub, sink, part, target);
      throw UpdateException(
        'Download unterbrochen: ${e is SocketException || e is TimeoutException || e is HttpException ? 'Netzwerkfehler' : e}',
      );
    }
  }

  Future<void> _discard(
    StreamSubscription<List<int>>? sub,
    IOSink? sink,
    File part,
    File target,
  ) async {
    try {
      await sub?.cancel();
    } catch (_) {}
    try {
      await sink?.close();
    } catch (_) {}
    for (final f in [part, target]) {
      try {
        if (await f.exists()) await f.delete();
      } catch (_) {}
    }
  }

  /// Removes leftovers from earlier attempts.
  static Future<void> cleanup(Directory dir) async {
    if (!await dir.exists()) return;
    await for (final e in dir.list()) {
      if (e is File && (e.path.endsWith('.apk') || e.path.endsWith('.part'))) {
        try {
          await e.delete();
        } catch (_) {}
      }
    }
  }
}

class _DigestSink implements Sink<Digest> {
  late Digest value;
  @override
  void add(Digest data) => value = data;
  @override
  void close() {}
}

/// Final gate before Android's installer is opened. Checks what the archive
/// itself declares; the file name is irrelevant here.
void verifyDownloadedApk({
  required ApkInspection? apk,
  required InstalledApp installed,
  required UpdateInfo update,
}) {
  if (apk == null) {
    throw const UpdateException(
      'APK ist beschädigt und kann nicht gelesen werden.',
    );
  }
  if (apk.packageName != installed.packageName ||
      apk.packageName != kUpdatePackageName) {
    throw const UpdateException(
      'Falsche Paketkennung. Installation verhindert.',
    );
  }
  if (apk.versionCode <= installed.versionCode) {
    throw const UpdateException(
      'APK ist nicht neuer als die installierte Version (kein Downgrade).',
    );
  }
  if (update.versionCode > 0 && apk.versionCode != update.versionCode) {
    throw const UpdateException(
      'APK-Version widerspricht den Release-Metadaten.',
    );
  }
  if (apk.minSdk > installed.sdkInt) {
    throw const UpdateException('APK benötigt eine neuere Android-Version.');
  }
  if (apk.signingCertSha256.isEmpty) {
    throw const UpdateException('APK ist nicht signiert.');
  }
  if (installed.signingCertSha256.isNotEmpty &&
      !apk.signingCertSha256.any(installed.signingCertSha256.contains)) {
    throw const UpdateException(
      'APK ist mit einem anderen Schlüssel signiert. Android würde sie nicht als Update akzeptieren.',
    );
  }
}
