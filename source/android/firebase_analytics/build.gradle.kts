plugins {
    id("com.android.library") version "8.2.2"
    id("org.jetbrains.kotlin.android") version "2.1.0"
}

android {
    namespace = "com.godotx.firebase.analytics"
    compileSdk = 35

    defaultConfig {
        minSdk = 21
        consumerProguardFiles("consumer-rules.pro")
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

    // Firebase Analytics
    implementation("com.google.firebase:firebase-analytics:23.0.0")
}

