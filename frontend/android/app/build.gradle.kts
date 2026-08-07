import java.io.File
import java.util.Properties

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.inschemes.app"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.inschemes.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // The on-device llama.cpp bridge requires API 26. This still covers
        // Android 8+ devices while allowing the app to run a CPU/NEON fallback
        // on older chipsets without relying on vendor-specific acceleration.
        minSdk = 26
        targetSdk = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs.getByName("debug") {
        // This certificate is registered with the Android Google OAuth client if present.
        // The keystore itself is ignored by Git (android/.gitignore).
        val customKeystore = file("debug.keystore")
        if (customKeystore.exists()) {
            storeFile = customKeystore
            storePassword = "android"
            keyAlias = "androiddebugkey"
            keyPassword = "android"
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    packaging {
        jniLibs.pickFirsts += "**/libomp.so"
    }
}

// llama_flutter_android 0.2.6 links its ARM64 CPU backend against OpenMP but
// does not package the NDK runtime. Copy the matching runtime at build time so
// libllama_jni.so can load on a physical device without committing a binary.
val androidLocalProperties = Properties().apply {
    val localPropertiesFile = rootProject.file("local.properties")
    if (localPropertiesFile.exists()) {
        localPropertiesFile.inputStream().use(::load)
    }
}

val androidSdkPath = androidLocalProperties.getProperty("sdk.dir")
    ?: System.getenv("ANDROID_SDK_ROOT")
    ?: System.getenv("ANDROID_HOME")
    ?: error("Android SDK path is not configured.")

val ndkHostTag = System.getProperty("os.name").lowercase().let { osName ->
    when {
        osName.contains("win") -> "windows-x86_64"
        osName.contains("mac") -> "darwin-x86_64"
        else -> "linux-x86_64"
    }
}

val openMpRuntime = providers.provider {
    val clangRoot = File(
        androidSdkPath,
        "ndk/${android.ndkVersion}/toolchains/llvm/prebuilt/$ndkHostTag/lib/clang",
    )
    val clangVersionDirectory = clangRoot.listFiles()
        ?.filter(File::isDirectory)
        ?.maxByOrNull(File::getName)
        ?: error("Unable to find the NDK Clang runtime under $clangRoot")
    File(clangVersionDirectory, "lib/linux/aarch64/libomp.so").also { runtime ->
        check(runtime.isFile) {
            "The ARM64 OpenMP runtime is missing from the configured NDK: $runtime"
        }
    }
}

val generatedOpenMpJniDirectory = layout.buildDirectory
    .dir("generated/openmpJni")
    .get()
    .asFile
val copyOpenMpRuntime by tasks.registering(Copy::class) {
    from(openMpRuntime)
    into(File(generatedOpenMpJniDirectory, "arm64-v8a"))
}

android.sourceSets.getByName("main").jniLibs.srcDir(generatedOpenMpJniDirectory)

tasks.configureEach {
    if (
        name.startsWith("merge") &&
        (name.endsWith("NativeLibs") || name.endsWith("JniLibFolders"))
    ) {
        dependsOn(copyOpenMpRuntime)
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
