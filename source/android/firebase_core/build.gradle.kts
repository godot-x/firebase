plugins {
    id("com.android.library") version "8.2.2"
    id("org.jetbrains.kotlin.android") version "2.1.0"
}

android {
    namespace = "com.godotx.firebase.core"
    compileSdk = 34

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

    // Firebase Core
    implementation("com.google.firebase:firebase-common:22.0.1")
}

