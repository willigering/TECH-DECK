plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

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

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
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

tasks.matching { it.name == "assembleRelease" }.configureEach {
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
