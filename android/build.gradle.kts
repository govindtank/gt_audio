group = "com.govindtank.gt_audio"
version = "1.0.0"

plugins {
    id("com.android.library")
}

android {
    namespace = "com.govindtank.gt_audio"
    compileSdk = 34

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        minSdk = 21
    }
}

dependencies {
    implementation("androidx.core:core-ktx:1.13.1")
}
