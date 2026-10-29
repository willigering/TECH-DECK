/// Data types of the TECH//DECK GitHub updater.
library;

const String kUpdateRepoOwner = 'willigering';
const String kUpdateRepoName = 'TECH-DECK';
const String kUpdatePackageName = 'com.willigering.tech_deck';
const String kUpdateMetadataAsset = 'techdeck-update.json';

/// Facts about the running installation, read from Android's PackageManager.
class InstalledApp {
  const InstalledApp({
    required this.packageName,
    required this.versionName,
    required this.versionCode,
    required this.sdkInt,
    required this.abis,
    required this.signingCertSha256,
  });

  final String packageName;
  final String versionName;
  final int versionCode;
  final int sdkInt;
  final List<String> abis;
  final List<String> signingCertSha256;
}

/// One APK described by the release metadata.
class UpdateApk {
  const UpdateApk({
    required this.name,
    required this.url,
    required this.size,
    required this.sha256,
    required this.abis,
  });

  final String name;
  final Uri url;
  final int size;
  final String sha256;

  /// Empty list = universal APK.
  final List<String> abis;
}

/// A validated, newer, installable release candidate.
class UpdateInfo {
  const UpdateInfo({
    required this.tag,
    required this.versionName,
    required this.versionCode,
    required this.minSdk,
    required this.releaseNotes,
    required this.apk,
    required this.signingCertSha256,
    required this.htmlUrl,
  });

  final String tag;
  final String versionName;
  final int versionCode;
  final int minSdk;
  final String releaseNotes;
  final UpdateApk apk;
  final List<String> signingCertSha256;
  final Uri? htmlUrl;
}

/// What the archive itself says, read by Android after the download.
class ApkInspection {
  const ApkInspection({
    required this.packageName,
    required this.versionName,
    required this.versionCode,
    required this.minSdk,
    required this.signingCertSha256,
  });

  final String packageName;
  final String versionName;
  final int versionCode;
  final int minSdk;
  final List<String> signingCertSha256;
}

enum CheckOutcome { updateAvailable, upToDate, skipped, failed }

class CheckResult {
  const CheckResult(this.outcome, {this.update, this.message});
  final CheckOutcome outcome;
  final UpdateInfo? update;
  final String? message;
}

/// Raised for any condition that must stop the update without crashing.
class UpdateException implements Exception {
  const UpdateException(this.message);
  final String message;
  @override
  String toString() => message;
}
