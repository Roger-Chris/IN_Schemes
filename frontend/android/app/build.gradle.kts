import java.io.File
import java.util.Properties

val releaseKeystorePropertiesFile = rootProject.file("key.properties")
val releaseKeystoreProperties = Properties().apply {
    if (releaseKeystorePropertiesFile.isFile) {
        releaseKeystorePropertiesFile.inputStream().use(::load)
    }
}
val requiredReleaseSigningFields =
    listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
val hasReleaseSigning = requiredReleaseSigningFields.all { field ->
    !releaseKeystoreProperties.getProperty(field).isNullOrBlank()
}

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
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // MSS currently ships English and Tamil. Excluding unused dependency
    // locales keeps direct-download APKs smaller without changing fallback
    // resources.
    androidResources.localeFilters += listOf("en", "ta")

    signingConfigs.getByName("debug") {
        // Use repo-specific debug.keystore if available, otherwise fall back to standard Android debug keystore.
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

    if (hasReleaseSigning) {
        signingConfigs.create("release") {
            storeFile = rootProject.file(
                releaseKeystoreProperties.getProperty("storeFile"),
            )
            storePassword = releaseKeystoreProperties.getProperty("storePassword")
            keyAlias = releaseKeystoreProperties.getProperty("keyAlias")
            keyPassword = releaseKeystoreProperties.getProperty("keyPassword")
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                null
            }

            // AGP 9 uses R8 full mode and optimized resource shrinking.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }

    packaging {
        jniLibs.pickFirsts += "**/libomp.so"
    }

    lint {
        // Flutter regenerates the ignored local.properties file using Windows
        // path escaping that Android lint misidentifies as a source error.
        disable += "PropertyEscape"
    }
}

// Keep debug builds and IDE sync usable without production credentials, while
// preventing an unsigned release artifact from being created accidentally.
val appReleaseRequested = gradle.startParameter.taskNames.any { taskName ->
    taskName.contains("Release", ignoreCase = true)
}
if (appReleaseRequested && !hasReleaseSigning) {
    throw GradleException(
        "Release signing is not configured. Copy android/key.properties.example " +
            "to android/key.properties and provide the release keystore values.",
    )
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
