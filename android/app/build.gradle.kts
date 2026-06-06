plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.aeca.asistencia"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

applicationVariants.all {
        val variant = this
        variant.outputs.all {
            val output = this as com.android.build.gradle.internal.api.BaseVariantOutputImpl
            output.outputFileName = "app-debug.apk"
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17" 
    }

   defaultConfig {
        applicationId = "com.aeca.asistencia"
        
        minSdk = flutter.minSdkVersion 
        targetSdk = 34 
        versionCode = 2 
        versionName = "1.0.1" 
        
        multiDexEnabled = true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}


flutter {
    source = "../.."
}
apply(plugin = "com.google.gms.google-services")
