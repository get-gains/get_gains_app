import com.android.build.api.dsl.ApplicationExtension
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
    // Unity 6000.4 requires NDK r27c (27.2.12479018) — must match unityLibrary
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
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // Unity only ships ARM native libs (libmain.so etc).
        // ndk.abiFilters is intentionally left unset here — AGP auto-detects
        // available ABIs from dependencies. Setting it conflicts with
        // --split-per-abi because Flutter adds x86_64 to the split filter,
        // but Unity doesn't provide x86_64 .so files. The split is
        // overridden to ARM-only in afterEvaluate below.
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
            pickFirsts += setOf("**/libc++_shared.so")
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
    // Unity only ships ARM native libraries. When --split-per-abi is active,
    // Flutter's Gradle Plugin adds x86_64 to the split filter, but unityLibrary
    // has no x86_64 .so files. Override the split to ARM-only.
    extensions.findByType(ApplicationExtension::class.java)?.splits?.let { splits ->
        val abi = splits.abi
        if (abi.isEnable) {
            abi.reset()
            abi.include("armeabi-v7a", "arm64-v8a")
            abi.isUniversalApk = true
        }
    }

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
