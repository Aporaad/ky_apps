pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        file("local.properties").inputStream().use { properties.load(it) }
        val flutterSdkPath = properties.getProperty("flutter.sdk")
        require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
        flutterSdkPath
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        maven { url = uri("https://maven.aliyun.com/repository/google") }
        maven { url = uri("https://maven.aliyun.com/repository/public") }
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.7.0" apply false
    // share_plus 12.0.2 يُصرَّف ضد Kotlin 2.2.0 — يجب أن تكون إضافة Kotlin >= 2.2.0
    // share_plus 12.0.2 is compiled against Kotlin 2.2.0 stdlib; the plugin must read that metadata.
    id("org.jetbrains.kotlin.android") version "2.2.0" apply false
}

include(":app")
