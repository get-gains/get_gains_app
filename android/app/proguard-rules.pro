# FFmpegKit — prevent R8 from stripping classes loaded via JNI/reflection.
# Without these rules, release builds crash on launch with:
#   NoClassDefFoundError: com.antonkarpenko.ffmpegkit.FFmpegKitConfig
# See: https://get-gains.sentry.io/issues/FLUTTER-2K/
-keep class com.antonkarpenko.ffmpegkit.** { *; }
-keepclassmembers class com.antonkarpenko.ffmpegkit.** { *; }
-dontwarn com.antonkarpenko.ffmpegkit.**
