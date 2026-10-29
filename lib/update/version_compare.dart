/// Semantic version comparison for TECH//DECK tags like `v.1.7.11`,
/// `v1.7.12` or `1.7.12+23`.
library;

class SemVer implements Comparable<SemVer> {
  const SemVer(this.parts, {this.build});
  final List<int> parts;
  final int? build;

  static final _re = RegExp(r'^[vV]?\.?\s*(\d+(?:\.\d+){0,3})(?:\+(\d+))?$');

  /// Returns null for anything that is not a plain stable version.
  static SemVer? tryParse(String? raw) {
    if (raw == null) return null;
    final m = _re.firstMatch(raw.trim());
    if (m == null) return null;
    final parts = m.group(1)!.split('.').map(int.parse).toList();
    while (parts.length < 3) {
      parts.add(0);
    }
    final build = m.group(2) == null ? null : int.parse(m.group(2)!);
    return SemVer(List.unmodifiable(parts), build: build);
  }

  @override
  int compareTo(SemVer other) {
    final n = parts.length > other.parts.length
        ? parts.length
        : other.parts.length;
    for (var i = 0; i < n; i++) {
      final a = i < parts.length ? parts[i] : 0;
      final b = i < other.parts.length ? other.parts[i] : 0;
      if (a != b) return a.compareTo(b);
    }
    return 0;
  }

  @override
  String toString() => parts.join('.');
}

/// An update is only offered when versionCode is strictly greater (Android
/// refuses downgrades and same-code reinstalls anyway) and versionName is not
/// lower. Both must agree, so a manipulated label cannot force a downgrade.
bool isNewerRelease({
  required String installedName,
  required int installedCode,
  required String candidateName,
  required int candidateCode,
}) {
  if (candidateCode <= installedCode) return false;
  final a = SemVer.tryParse(installedName);
  final b = SemVer.tryParse(candidateName);
  if (b == null) return false;
  if (a == null) return true;
  return b.compareTo(a) >= 0;
}
