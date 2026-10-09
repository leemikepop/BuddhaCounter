import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

android {
    namespace = "com.yichung.lee.buddha_counter"
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_21
        targetCompatibility = JavaVersion.VERSION_21
    }

    defaultConfig {
        // 嚴格保留 Google Play 上架專用 applicationId，以支援無縫升級更新
        applicationId = "com.yichung.lee.count4"
        minSdk = flutter.minSdkVersion
        targetSdk = 37
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val keyPath = keystoreProperties.getProperty("storeFile")
                ?: System.getenv("KEYSTORE_PATH")
                ?: "../keystore/leeyc.jks"
            val sPassword = keystoreProperties.getProperty("storePassword")
                ?: System.getenv("KEYSTORE_PASSWORD")
            val kAlias = keystoreProperties.getProperty("keyAlias")
                ?: System.getenv("KEY_ALIAS")
            val kPassword = keystoreProperties.getProperty("keyPassword")
                ?: System.getenv("KEY_PASSWORD")

            val keystoreFile = file(keyPath)
            if (keystoreFile.exists() && !sPassword.isNullOrBlank() && !kAlias.isNullOrBlank() && !kPassword.isNullOrBlank()) {
                storeFile = keystoreFile
                storePassword = sPassword
                keyAlias = kAlias
                keyPassword = kPassword
            } else {
                // 若未提供金鑰密碼或檔案不存在，安全 fallback 回 debug 簽署，確保 CI/CD 或全新環境編譯不中斷
                val debugConfig = signingConfigs.getByName("debug")
                val fallbackFile = debugConfig.storeFile ?: file("${System.getProperty("user.home")}/.android/debug.keystore")
                if (!fallbackFile.exists()) {
                    fallbackFile.parentFile?.mkdirs()
                    try {
                        ProcessBuilder(
                            "keytool", "-genkeypair",
                            "-alias", "androiddebugkey",
                            "-keypass", "android",
                            "-keystore", fallbackFile.absolutePath,
                            "-storepass", "android",
                            "-dname", "CN=Android Debug,O=Android,C=US",
                            "-keyalg", "RSA",
                            "-keysize", "2048",
                            "-validity", "10000"
                        ).start().waitFor()
                    } catch (e: Exception) {
                        println("Notice: Could not auto-generate debug keystore: ${e.message}")
                    }
                }
                storeFile = fallbackFile
                storePassword = debugConfig.storePassword ?: "android"
                keyAlias = debugConfig.keyAlias ?: "androiddebugkey"
                keyPassword = debugConfig.keyPassword ?: "android"
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_21
    }
}

flutter {
    source = "../.."
}
