plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    dependenciesInfo {
        includeInApk = false
        includeInBundle = false
    }
    namespace = "org.orixon.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion
    ndkPath = "/tmp/jni-ndk-shim"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "org.orixon.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        ndk {
            debugSymbolLevel = "NONE"
        }
    }

    packaging {
        jniLibs {
            // Strip debug symbols via llvm-strip shim
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
            ndk {
                debugSymbolLevel = "NONE"
            }
        }
    }
}

tasks.configureEach {
    if (name.contains("ExtractReleaseNativeSymbolTables") ||
        name.contains("extractReleaseNativeSymbolTables")) {
        enabled = false
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
