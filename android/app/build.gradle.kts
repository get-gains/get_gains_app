plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.getgains.app"
    compileSdk = 36
    // Unity 6000.0 requires NDK r27c (27.2.12479018)
    ndkVersion = "27.2.12479018"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.getgains.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // Unity 6000.0 requires minSdk 34
        minSdk = 34
        targetSdk = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // Unity only ships ARM native libs (libmain.so etc). Use an ARM64 emulator or a real device.
        ndk {
            abiFilters.clear()
            abiFilters.addAll(listOf("armeabi-v7a", "arm64-v8a"))
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    packaging {
        jniLibs {
            useLegacyPackaging = true
        }
    }
}

dependencies {
    // Unity library dependency
    implementation(project(":unityLibrary"))
}

// Ensure Unity library's native libs are built and merged before packaging
afterEvaluate {
    tasks.findByName("mergeDebugJniLibFolders")?.dependsOn(":unityLibrary:buildIl2Cpp")
    tasks.findByName("mergeDebugJniLibFolders")?.dependsOn(":unityLibrary:mergeDebugJniLibFolders")
    tasks.findByName("mergeReleaseJniLibFolders")?.dependsOn(":unityLibrary:buildIl2Cpp")
    tasks.findByName("mergeReleaseJniLibFolders")?.dependsOn(":unityLibrary:mergeReleaseJniLibFolders")
}

flutter {
    source = "../.."
}
