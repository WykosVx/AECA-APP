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

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17" 
    }

   defaultConfig {
        applicationId = "com.aeca.asistencia"
        
        minSdk = flutter.minSdkVersion // Bajamos a 21 para que sea compatible con TODO
        targetSdk = 34 // <--- PONELO MANUAL EN 34. Esto quita el error de versión.
        
        versionCode = 2 // Subilo a 2 para que el celu lo tome como actualización
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
