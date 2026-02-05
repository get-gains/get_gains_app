import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

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
    ndkVersion = "28.2.13676358"

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
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // Unity only ships ARM native libs (libmain.so etc). Use an ARM64 emulator or a real device.
        ndk {
            abiFilters.clear()
            abiFilters.addAll(listOf("armeabi-v7a", "arm64-v8a"))
        }
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it as String) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
    
    packaging {
        jniLibs {
            useLegacyPackaging = true
        }
    }
}

dependencies {
    // Unity library dependency (optional; only when unityLibrary is exported to android/unityLibrary)
    if (findProject(":unityLibrary") != null) {
        implementation(project(":unityLibrary"))
    }
}

// Ensure Unity library's native libs are built and merged before packaging (only when present)
afterEvaluate {
    if (findProject(":unityLibrary") != null) {
        tasks.findByName("mergeDebugJniLibFolders")?.dependsOn(":unityLibrary:buildIl2Cpp")
        tasks.findByName("mergeDebugJniLibFolders")?.dependsOn(":unityLibrary:mergeDebugJniLibFolders")
        tasks.findByName("mergeReleaseJniLibFolders")?.dependsOn(":unityLibrary:buildIl2Cpp")
        tasks.findByName("mergeReleaseJniLibFolders")?.dependsOn(":unityLibrary:mergeReleaseJniLibFolders")
    }
}

flutter {
    source = "../.."
}
