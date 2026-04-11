pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            val file = file("local.properties")
            if (file.exists()) {
                file.inputStream().use { properties.load(it) }
            }
            properties.getProperty("flutter.sdk")
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-gradle-plugin") version "1.0.0" apply false
    id("com.android.application") version "8.9.1" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
}

include(":app")
