import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.Properties
import java.util.TimeZone

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("kotlin-parcelize") 
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.oxpay.o7lite"
    compileSdk = flutter.compileSdkVersion
    // ndkVersion = flutter.ndkVersion
    // Fix this issue by using the highest Android NDK version (they are backward compatible).
    ndkVersion = "28.2.13676358"

    // Enable BuildConfig generation for product flavors
    buildFeatures {
        buildConfig = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Ensure Java interoperability is configured correctly.
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
        // Improve Java compatibility.
        freeCompilerArgs = listOf("-Xjvm-default=all")
    }

    // Enable JUnit5 for Kotest property-based testing
    testOptions {
        unitTests.all {
            it.useJUnitPlatform()
        }
    }

    aaptOptions {
        noCompress += "txt"
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.oxpay.o7lite"
        minSdk = flutter.minSdkVersion
        targetSdk = 35
        versionCode = 52 //flutterVersionCode.toInteger()
        versionName = "3.0.45" //flutterVersionName
        multiDexEnabled = true
        multiDexKeepFile = file("src/main/res/raw/multidex_config.txt")
        
        // Filter ABIs to reduce APK size - only ARM architectures for real devices
        // Excludes x86/x86_64 (emulator only) to save ~40MB
        ndk {
            abiFilters += listOf("armeabi-v7a", "arm64-v8a")
        }
    }

    // ============================================================================
    // SOURCE SET CONFIGURATION (Main only - flavor source sets configured below)
    // ============================================================================
    sourceSets {
        getByName("main") {
            java.srcDirs("src/main/kotlin")
        }
    }

    signingConfigs {
        // Load signing properties from local.properties
        val localProperties = Properties()
        val localPropertiesFile = rootProject.file("local.properties")
        if (localPropertiesFile.exists()) {
            localProperties.load(localPropertiesFile.inputStream())
        }

        // Default release signing config (used for all flavors except wizarpos)
        create("release") {
            enableV1Signing = true
            enableV2Signing = true
            storeFile = file(localProperties.getProperty("RELEASE_STORE_FILE") ?: "../release-keystore/o7lite-keystore")
            storePassword = localProperties.getProperty("RELEASE_STORE_PASSWORD") ?: ""
            keyAlias = localProperties.getProperty("RELEASE_KEY_ALIAS") ?: ""
            keyPassword = localProperties.getProperty("RELEASE_KEY_PASSWORD") ?: ""
        }

        // WizarPOS signing config (separate keystore)
        create("wizarposRelease") {
            enableV1Signing = true
            enableV2Signing = true
            storeFile = file(localProperties.getProperty("WIZARPOS_STORE_FILE") ?: "../release-keystore/keystore-o7lite-wizarpos")
            storePassword = localProperties.getProperty("WIZARPOS_STORE_PASSWORD") ?: ""
            keyAlias = localProperties.getProperty("WIZARPOS_KEY_ALIAS") ?: ""
            keyPassword = localProperties.getProperty("WIZARPOS_KEY_PASSWORD") ?: ""
            // Forces V1 signing to be enabled, only can enable both v1 and v2 if minSdkVersion < 24 (which is the case for wizarpos flavor)
        }
    }
    buildTypes {
        release {
            // Ensure release builds are not debuggable
            isDebuggable = false

            isMinifyEnabled = true
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"), 
                "proguard-rules.pro",
                "consumer-rules.pro"
            )
        }
        
        debug {
            isMinifyEnabled = false
            isShrinkResources = false  
            multiDexEnabled = true
            // Disable PNG crunching to speed up build times for debug builds
            isCrunchPngs = false  // increases build speed by skipping PNG crunching
            proguardFiles(
                getDefaultProguardFile("proguard-android.txt"),
                "proguard-rules.pro"
            )
        }
    }

    packaging {
        resources {
            excludes += "/META-INF/DEPENDENCIES"
            excludes += "/META-INF/LICENSE"
            excludes += "/META-INF/LICENSE.txt"
            excludes += "/META-INF/license.txt"
            excludes += "/META-INF/NOTICE"
            excludes += "/META-INF/NOTICE.txt"
            excludes += "/META-INF/notice.txt"
            excludes += "/META-INF/ASL2.0"
            excludes += "/META-INF/*.kotlin_module"
            // Exclude dump_syms debug symbols (~33MB savings)
            excludes += "dump_syms/**"
        }
        jniLibs {
            // Exclude x86/x86_64 native libraries from dependencies (~15MB savings)
            excludes += "lib/x86/**"
            excludes += "lib/x86_64/**"
        }
    }

    // Flavor dimension declaration
    flavorDimensions += "device"
    val wizarPosMinSdk = 23

    // Product flavors configuration
    // Each POS device brand has its own flavor with independent versionCode/versionName
    // All flavors use same applicationId: com.oxpay.o7lite
    // ABI filters exclude x86/x86_64 (simulator) to reduce APK size - real devices only
    productFlavors {
        // ============================================================================
        // POS DEVICE FLAVORS
        // ============================================================================
        
        // Sunmi POS terminals (V1, V2, P1, P2, etc.)
        // Detection: Build.BRAND contains "SUNMI"
        create("sunmi") {
            dimension = "device"
            minSdk = 24
            versionCode = 80
            versionName = "3.0.63"
            buildConfigField("String", "DEVICE_TYPE", "\"sunmi\"")
            buildConfigField("String", "DEVICE_BRAND", "\"SUNMI\"")
            ndk {
                abiFilters.clear()
                abiFilters += listOf("armeabi-v7a", "arm64-v8a")
            }
            signingConfig = signingConfigs.getByName("release")
        }

        // Landi POS terminals
        // Detection: Build.BRAND contains "LANDI"
        create("landi") {
            dimension = "device"
            minSdk = 24
            versionCode = 79
            versionName = "3.0.63"
            buildConfigField("String", "DEVICE_BRAND", "\"LANDI\"")
            ndk {
                abiFilters.clear()
                abiFilters += listOf("armeabi-v7a", "arm64-v8a")
            }
            signingConfig = signingConfigs.getByName("release")
        }

        // Castle POS terminals
        // Detection: Build.BRAND/MODEL contains "CASTLE"
        create("castle") {
            dimension = "device"
            minSdk = 24
            versionCode = 59
            versionName = "3.0.50"
            buildConfigField("String", "DEVICE_TYPE", "\"castle\"")
            buildConfigField("String", "DEVICE_BRAND", "\"CASTLE\"")
            ndk {
                abiFilters.clear()
                abiFilters += listOf("armeabi-v7a", "arm64-v8a")
            }
            signingConfig = signingConfigs.getByName("release")
        }

        // Anfu POS terminals
        // Detection: Build.BRAND contains "ANFU"
        create("anfu") {
            dimension = "device"
            minSdk = 24
            versionCode = 1
            versionName = "1.0.0"
            buildConfigField("String", "DEVICE_TYPE", "\"anfu\"")
            buildConfigField("String", "DEVICE_BRAND", "\"ANFU\"")
            ndk {
                abiFilters.clear()
                abiFilters += listOf("armeabi-v7a", "arm64-v8a")
            }
            signingConfig = signingConfigs.getByName("release")
        }

        // WizarPOS Q2 terminals
        // Detection: Build.MODEL contains "WIZARPOS Q2"
        // Uses separate signing config: wizarposRelease
        // to enable v1, v2 signing for minSdk < 24 (WizarPOS Q2 runs Android 7.1.2 / API 25)
        create("wizarpos") {
            dimension = "device"
            minSdk = wizarPosMinSdk
            versionCode = 61
            versionName = "3.0.54"
            buildConfigField("String", "DEVICE_TYPE", "\"wizarpos\"")
            buildConfigField("String", "DEVICE_BRAND", "\"WIZARPOS\"")
            ndk {
                abiFilters.clear()
                abiFilters += listOf("armeabi-v7a", "arm64-v8a")
            }
            signingConfig = signingConfigs.getByName("wizarposRelease")
        }

        // Coherent POS terminals (Centerm-based)
        // Detection: Build.BRAND contains "COHERENT" or Build.MODEL contains "CENTERM"
        // minSdk = 22: Coherent devices run Android 5.1.x (API 22 / Lollipop)
        create("coherent") {
            dimension = "device"
            minSdk = flutter.minSdkVersion// Coherent devices run Android 5.1.x (API 22 / Lollipop)
            versionCode = 2
            versionName = "1.0.0"
            buildConfigField("String", "DEVICE_TYPE", "\"coherent\"")
            buildConfigField("String", "DEVICE_BRAND", "\"COHERENT\"")
            ndk {
                abiFilters.clear()
                abiFilters += listOf("armeabi-v7a", "arm64-v8a")
            }
            signingConfig = signingConfigs.getByName("release")
        }

        // Morefun (MF) POS terminals (YSDK / com.morefun.ysdk system service)
        // Detection: Build.BRAND/MANUFACTURER/MODEL contains "MOREFUN"
        create("morefun") {
            dimension = "device"
            minSdk = 24
            versionCode = 2
            versionName = "1.0.1"
            buildConfigField("String", "DEVICE_TYPE", "\"morefun\"")
            buildConfigField("String", "DEVICE_BRAND", "\"MOREFUN\"")
            ndk {
                abiFilters.clear()
                abiFilters += listOf("armeabi-v7a", "arm64-v8a")
            }
            signingConfig = signingConfigs.getByName("release")
        }

        // ============================================================================
        // MOBILE FLAVOR
        // ============================================================================
        
        // Standard mobile devices (phones/tablets)
        // minSdk = 29 (Android 10) required for Google Play Store 16KB page alignment compliance
        // This flavor excludes all POS SDK dependencies to avoid non-16KB aligned native libraries
        create("mobile") {
            dimension = "device"
            minSdk = 29  // Android 10 - required for 16KB page alignment compliance
            versionCode = 55
            versionName = "3.0.42"
            buildConfigField("String", "DEVICE_TYPE", "\"mobile\"")
            buildConfigField("String", "DEVICE_BRAND", "\"GENERIC\"")
            ndk {
                abiFilters.clear()
                abiFilters += listOf("armeabi-v7a", "arm64-v8a")
            }
            signingConfig = signingConfigs.getByName("release")
        }
    }
    
    // ============================================================================
    // FLAVOR SOURCE SET CONFIGURATION
    // ============================================================================
    // 
    // Configure source sets for each flavor AFTER product flavors are defined.
    // 
    // Architecture:
    // - src/main/kotlin/     - Shared code used by ALL flavors (no POS SDK imports)
    // - src/pos/kotlin/      - POS-specific code (MainApplication, MainActivityRefactored, 
    //                          printer services) - used by POS flavors only
    // - src/mobile/kotlin/   - Mobile-specific code (stub implementations) - used by mobile flavor only
    // 
    // This ensures:
    // - Mobile flavor compiles without POS SDK dependencies
    // - POS flavors have full printer functionality
    // - No code duplication between flavors
    // ============================================================================
    sourceSets {
        // Mobile flavor source set - provides POS-free stub implementations
        getByName("mobile") {
            java.srcDirs("src/mobile/kotlin")
        }
        
        // POS flavor source sets - all include the pos source directory
        getByName("sunmi") {
            java.srcDirs("src/pos/kotlin")
        }
        getByName("landi") {
            java.srcDirs("src/pos/kotlin")
        }
        getByName("castle") {
            java.srcDirs("src/pos/kotlin")
        }
        getByName("anfu") {
            java.srcDirs("src/pos/kotlin")
        }
        getByName("wizarpos") {
            java.srcDirs("src/pos/kotlin")
        }
        getByName("coherent") {
            java.srcDirs("src/pos/kotlin")
        }
        getByName("morefun") {
            java.srcDirs("src/pos/kotlin")
        }
    }
}

android.applicationVariants.all {
    appendVersionNameVersionCode(this)
}

flutter {
    source = "../.."
}

dependencies {
    configurations.configureEach {
        exclude(group = "com.google.zxing")
        exclude(group = "androidx.profileinstaller")
    }

    // Enable core library desugaring for Java 8+ APIs on lower API levels
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")

    // Kotest for property-based testing (security validation)
    testImplementation("io.kotest:kotest-runner-junit5:5.8.0")
    testImplementation("io.kotest:kotest-assertions-core:5.8.0")
    testImplementation("io.kotest:kotest-property:5.8.0")
    testImplementation("io.mockk:mockk:1.13.9")

    implementation("androidx.core:core-ktx:1.6.0")

    implementation("androidx.constraintlayout:constraintlayout:2.1.4")

    implementation("com.android.support:appcompat-v7:28.0.0")
    implementation("androidx.appcompat:appcompat:1.6.1")
    implementation("com.google.android.material:material:1.11.0")
    implementation("androidx.recyclerview:recyclerview:1.1.0")
    implementation("androidx.cardview:cardview:1.0.0")
    implementation("androidx.annotation:annotation:1.1.0")
    implementation("androidx.palette:palette-ktx:1.0.0")
    implementation("androidx.constraintlayout:constraintlayout:2.1.4")

    // ============================================================================
    // PRINTER SDK DEPENDENCIES - POS FLAVORS ONLY (EXCLUDED FROM MOBILE)
    // ============================================================================
    // This app supports multiple POS terminal brands, each with their own printer SDK.
    // Device detection is done via Build.BRAND/Build.MODEL in Utils.kt
    // 
    // IMPORTANT: POS SDK dependencies are included in ALL POS flavors but EXCLUDED
    // from the "mobile" flavor build. This is required for Google Play Store
    // compliance with 16KB page alignment requirements (Android 10+).
    // 
    // The mobile flavor has NO POS SDK dependencies, allowing it to pass 16KB
    // page alignment checks. All POS flavors include all SDKs for compilation
    // compatibility (main source set references multiple SDKs).
    // ============================================================================

    // Define POS SDK dependencies as variables for reuse across flavors
    val sunmiSdk = "com.sunmi:printerlibrary:1.0.13"
    val castleSdk = files("src/main/libs/castle_printer_sdk_0.0.3.jar")
    val anfuSdk = files("src/main/libs/anfu_printer_sdk.aar")
    val landiSdk = files("src/main/libs/landi_omnidriver_sdk_0.0.1.aar")
    val wizarposSdk = files("src/main/libs/wizarpos_printer_sdk_1.7.5.1.aar")
    val coherentSdk = files("src/main/libs/coherent_smartpos_sdk_3.1.5.jar")
    val morefunSdk = files("src/main/libs/morefun_ysdk_6.06.jar")

    // ============================================================================
    // SUNMI FLAVOR - Include all POS SDKs for compilation compatibility
    // ============================================================================
    "sunmiImplementation"(sunmiSdk)
    "sunmiImplementation"(castleSdk)
    "sunmiImplementation"(anfuSdk)
    "sunmiImplementation"(landiSdk)
    "sunmiImplementation"(wizarposSdk)
    "sunmiImplementation"(coherentSdk)
    "sunmiImplementation"(morefunSdk)

    // ============================================================================
    // CASTLE FLAVOR - Include all POS SDKs for compilation compatibility
    // ============================================================================
    "castleImplementation"(sunmiSdk)
    "castleImplementation"(castleSdk)
    "castleImplementation"(anfuSdk)
    "castleImplementation"(landiSdk)
    "castleImplementation"(wizarposSdk)
    "castleImplementation"(coherentSdk)
    "castleImplementation"(morefunSdk)

    // ============================================================================
    // ANFU FLAVOR - Include all POS SDKs for compilation compatibility
    // ============================================================================
    "anfuImplementation"(sunmiSdk)
    "anfuImplementation"(castleSdk)
    "anfuImplementation"(anfuSdk)
    "anfuImplementation"(landiSdk)
    "anfuImplementation"(wizarposSdk)
    "anfuImplementation"(coherentSdk)
    "anfuImplementation"(morefunSdk)

    // ============================================================================
    // LANDI FLAVOR - Include all POS SDKs for compilation compatibility
    // ============================================================================
    "landiImplementation"(sunmiSdk)
    "landiImplementation"(castleSdk)
    "landiImplementation"(anfuSdk)
    "landiImplementation"(landiSdk)
    "landiImplementation"(wizarposSdk)
    "landiImplementation"(coherentSdk)
    "landiImplementation"(morefunSdk)

    // ============================================================================
    // WIZARPOS FLAVOR - Include all POS SDKs for compilation compatibility
    // ============================================================================
    "wizarposImplementation"(sunmiSdk)
    "wizarposImplementation"(castleSdk)
    "wizarposImplementation"(anfuSdk)
    "wizarposImplementation"(landiSdk)
    "wizarposImplementation"(wizarposSdk)
    "wizarposImplementation"(coherentSdk)
    "wizarposImplementation"(morefunSdk)

    // ============================================================================
    // COHERENT FLAVOR - Include all POS SDKs for compilation compatibility
    // ============================================================================
    "coherentImplementation"(sunmiSdk)
    "coherentImplementation"(castleSdk)
    "coherentImplementation"(anfuSdk)
    "coherentImplementation"(landiSdk)
    "coherentImplementation"(wizarposSdk)
    "coherentImplementation"(coherentSdk)
    "coherentImplementation"(morefunSdk)

    // ============================================================================
    // MOREFUN FLAVOR - Include all POS SDKs for compilation compatibility
    // ============================================================================
    "morefunImplementation"(sunmiSdk)
    "morefunImplementation"(castleSdk)
    "morefunImplementation"(anfuSdk)
    "morefunImplementation"(landiSdk)
    "morefunImplementation"(wizarposSdk)
    "morefunImplementation"(coherentSdk)
    "morefunImplementation"(morefunSdk)

    // ============================================================================
    // MOBILE FLAVOR - NO POS SDK dependencies (16KB page alignment compliance)
    // ============================================================================
    // Mobile flavor intentionally has NO POS SDK dependencies.
    // This ensures the APK passes Google Play Store 16KB page alignment checks.
    // Mobile-specific source set files (src/mobile/kotlin/) provide stub
    // implementations that don't reference any POS SDK classes.

    implementation("com.google.code.gson:gson:2.10")

    implementation("com.squareup.retrofit2:retrofit:2.11.0")
    implementation("com.squareup.retrofit2:converter-gson:2.11.0")

    implementation("com.github.bumptech.glide:glide:4.16.0")

    implementation("com.android.support:multidex:2.0.1")
}

// Force all dependencies to use the same JVM target
configurations.all {
    resolutionStrategy {
        eachDependency {
            if (requested.group == "org.jetbrains.kotlin") {
                useVersion("2.1.0")
            }
        }
    }
}

tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
    kotlinOptions {
        jvmTarget = "17"
        freeCompilerArgs = listOf("-Xjvm-default=all")
    }
}

// Custom function to append version name and code to the APK filename
// Output format: o7lite-x-{flavorName}-{versionName}-{buildType}-{dd-MM-yyyy}.apk
// Example: o7lite-x-pos-1.0.0-release-15-01-2025.apk
fun appendVersionNameVersionCode(variant: com.android.build.gradle.api.ApplicationVariant) {
    variant.outputs.all { 
        val output = this as com.android.build.gradle.api.ApkVariantOutput
        val dateFormat = SimpleDateFormat("dd-MM-yyyy", Locale.US)
        dateFormat.timeZone = TimeZone.getTimeZone("UTC")
        val date = dateFormat.format(Date())
        
        // Extract flavor name from the variant's product flavors
        val flavorName = variant.productFlavors.firstOrNull()?.name ?: "unknown"
        val buildType = variant.buildType.name
        
        output.outputFileName = "o7lite-x-${flavorName}-v${variant.versionName}_${variant.versionCode}-${buildType}-${date}.apk"
    }
}
