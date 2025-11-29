plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.ski.infinicard"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.ski.infinicard"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
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

flutter {
    source = "../.."
}

// Copy tessdata traineddata from Flutter assets into Android assets/tessdata so
// the native Tesseract engine can find the files at runtime. This runs before
// the build (preBuild) and is safe when the source file doesn't exist.
tasks.register<Copy>("copyTessdata") {
    val srcFile = file("${rootProject.projectDir}/assets/eng.traineddata")
    val destDir = file("${projectDir}/src/main/assets/tessdata")
    // Only copy if the source exists
    if (srcFile.exists()) {
        from(srcFile)
        into(destDir)
        doFirst {
            destDir.mkdirs()
            println("[build] Copying eng.traineddata -> ${destDir.absolutePath}")
        }
    } else {
        doFirst {
            println("[build] eng.traineddata not found in project assets; skipping copy.")
        }
    }
}

tasks.named("preBuild") {
    dependsOn("copyTessdata")
}
