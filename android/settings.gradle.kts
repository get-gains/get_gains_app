pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.10.0" apply false
    id("com.android.library") version "8.10.0" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
}

include(":app")
// Unity export is optional (not in repo); include only when present so CI/fresh clones can build.
// Support both structures: flat (unityLibrary/build.gradle) or nested (unityLibrary/unityLibrary/build.gradle).
val unityLibraryFlat = file("unityLibrary/build.gradle")
val unityLibraryNested = file("unityLibrary/unityLibrary/build.gradle")
val unityLibraryNestedKts = file("unityLibrary/unityLibrary/build.gradle.kts")
when {
    unityLibraryFlat.exists() -> {
        include(":unityLibrary")
        project(":unityLibrary").projectDir = file("unityLibrary")
    }
    unityLibraryNested.exists() || unityLibraryNestedKts.exists() -> {
        include(":unityLibrary")
        project(":unityLibrary").projectDir = file("unityLibrary/unityLibrary")
    }
}