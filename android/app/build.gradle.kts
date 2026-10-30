import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing (see README, "Veröffentlichung und Updates > Signierung").
// Published APKs up to 1.7.11 are signed with the developer's *local* Android
// debug keystore (CN=Android Debug, cert SHA-256 ace2efc2...2e34). Updates are
// only installable over them when the very same key is used again.
// Source of the key, in this order:
//   1. Environment (CI): TECHDECK_KEYSTORE_PATH, TECHDECK_KEYSTORE_PASSWORD,
//      TECHDECK_KEY_ALIAS, TECHDECK_KEY_PASSWORD
//   2. android/key.properties (git-ignored): storeFile, storePassword, keyAlias, keyPassword
//   No fallback: release builds FAIL without the release key (never debug-signed).
// Since 1.7.12 the release key is techdeck-release (cert SHA-256
// 0cea186bcac2a7b5874ede5d5bdf9dc4e8ed5ba876d6da7ec567278b07ee754d).
val keyProperties = Properties().apply {
    val f = rootProject.file("key.properties")
    if (f.isFile) f.inputStream().use { load(it) }
}
fun signingValue(env: String, prop: String): String? =
    System.getenv(env)?.takeIf { it.isNotBlank() } ?: keyProperties.getProperty(prop)
val releaseStoreFile = signingValue("TECHDECK_KEYSTORE_PATH", "storeFile")
val hasReleaseKey = releaseStoreFile != null && file(releaseStoreFile).isFile

android {
    namespace = "com.willigering.tech_deck"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.willigering.tech_deck"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKey) {
            create("techdeck") {
                storeFile = file(releaseStoreFile!!)
                storePassword = signingValue("TECHDECK_KEYSTORE_PASSWORD", "storePassword")
                keyAlias = signingValue("TECHDECK_KEY_ALIAS", "keyAlias")
                keyPassword = signingValue("TECHDECK_KEY_PASSWORD", "keyPassword")
            }
        }
    }

    buildTypes {
        release {
            if (hasReleaseKey) {
                signingConfig = signingConfigs.getByName("techdeck")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

// Keep Flutter's standard APK for its tooling and add a versioned release copy.
val apkVersion = flutter.versionName
val apkBuildNumber = flutter.versionCode
val releaseApkDirectory = layout.buildDirectory.dir("outputs/apk/release")
val namedApkDirectory = layout.buildDirectory.dir("outputs/flutter-apk")

tasks.matching { it.name == "assembleRelease" || it.name == "bundleRelease" }.configureEach {
    doFirst {
        if (!hasReleaseKey) {
            throw GradleException(
                "TECH//DECK: Release-Signierschlüssel fehlt (TECHDECK_KEYSTORE_PATH oder android/key.properties). Kein Debug-Fallback.",
            )
        }
    }
    doLast {
        val destination = namedApkDirectory.get().asFile
        destination.mkdirs()
        releaseApkDirectory.get().asFile.listFiles()
            ?.filter { it.isFile && it.extension == "apk" }
            ?.forEach { apk ->
                val abi = apk.name.removePrefix("app-").removeSuffix("-release.apk")
                val suffix = if (apk.name == "app-release.apk") "" else "-$abi"
                apk.copyTo(
                    destination.resolve("TECH-DECK-$apkVersion+$apkBuildNumber$suffix.apk"),
                    overwrite = true,
                )
            }
    }
}
