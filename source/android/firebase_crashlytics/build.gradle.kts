plugins {
    id("com.android.library") version "8.2.2"
    id("org.jetbrains.kotlin.android") version "2.1.0"
}

android {
    namespace = "com.godotx.firebase.crashlytics"
    compileSdk = 34

    defaultConfig {
        minSdk = 21
        consumerProguardFiles("proguard-firebase.pro")
    }

    buildTypes {
        getByName("release") {
            isMinifyEnabled = false
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }
}

dependencies {
    compileOnly("org.godotengine:godot:4.2.2.stable")
    
    // Firebase Crashlytics
    implementation("com.google.firebase:firebase-crashlytics:20.0.3")
    implementation("com.google.firebase:firebase-crashlytics-ndk:20.0.3")
}

