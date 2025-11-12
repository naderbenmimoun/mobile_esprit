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
    id("com.android.application") version "8.9.1" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
}

include(":app")

// NOTE: removed `rootProject.buildDir = file("C:/flutter_builds/${rootProject.name}/build")`
// The settings.gradle.kts script does not expose `buildDir`. If you need to change the build directory:
// - set `buildDir = file("C:/some/path")` inside the root build.gradle.kts (Project scope), or
// - move the project to a path without spaces (recommended on Windows), or
// - set an environment/Gradle property and apply it in the root project's build.gradle.kts.
