import java.io.FileInputStream
import java.util.Properties

val keystoreProperties =
    Properties().apply {
      val file = rootProject.file("key.properties")
      if (file.exists()) {
        load(FileInputStream(file))
      }
    }

plugins {
  id("com.android.application")
  id("org.jetbrains.kotlin.android")
  // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
  id("dev.flutter.flutter-gradle-plugin")
}

android {
  namespace = "com.android.ledgerone"
  compileSdk = flutter.compileSdkVersion
  ndkVersion = flutter.ndkVersion

  defaultConfig {
    applicationId = "com.android.ledgerone"
    minSdk = flutter.minSdkVersion
    targetSdk = flutter.targetSdkVersion
    versionCode = flutter.versionCode
    versionName = flutter.versionName
  }
  signingConfigs {
    create("release") {
      val storeFilePath =
          keystoreProperties.getProperty("storeFile")
              ?: error("storeFile is missing in android/key.properties")

      storeFile = file(storeFilePath)
      storePassword =
          keystoreProperties.getProperty("storePassword")
              ?: error("storePassword is missing in android/key.properties")
      keyAlias =
          keystoreProperties.getProperty("keyAlias")
              ?: error("keyAlias is missing in android/key.properties")
      keyPassword =
          keystoreProperties.getProperty("keyPassword")
              ?: error("keyPassword is missing in android/key.properties")
    }
  }
  buildTypes { getByName("release") { signingConfig = signingConfigs.getByName("release") } }

  compileOptions {
    sourceCompatibility = JavaVersion.VERSION_11
    targetCompatibility = JavaVersion.VERSION_11
  }

  kotlinOptions { jvmTarget = JavaVersion.VERSION_11.toString() }
}

flutter {
  source = "../.."
}
