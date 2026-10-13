plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.compose)
    alias(libs.plugins.google.gms.services)
}

android {
    namespace = "com.example.healthiez"
    compileSdk {
        version = release(36) {
            minorApiLevel = 1
        }
    }

    defaultConfig {
        applicationId = "com.example.healthiez"
        minSdk = 26
        //noinspection OldTargetApi
        targetSdk = 36
        versionCode = 1
        versionName = "1.0"

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    buildTypes {
        release {
            optimization {
                enable = false
            }
        }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
    buildFeatures {
        compose = true
    }
}

dependencies {
    // === CÁC THƯ VIỆN MẶC ĐỊNH CỦA ANDROID STUDIO (Giữ nguyên) ===
    implementation(platform(libs.androidx.compose.bom))
    implementation(libs.androidx.activity.compose)
    implementation(libs.androidx.compose.material3)
    implementation(libs.androidx.compose.ui)
    implementation(libs.androidx.compose.ui.graphics)
    implementation(libs.androidx.compose.ui.tooling.preview)
    implementation(libs.androidx.core.ktx)
    implementation(libs.androidx.lifecycle.runtime.ktx)
    testImplementation(libs.junit)
    androidTestImplementation(platform(libs.androidx.compose.bom))
    androidTestImplementation(libs.androidx.compose.ui.test.junit4)
    androidTestImplementation(libs.androidx.espresso.core)
    androidTestImplementation(libs.androidx.junit)
    debugImplementation(libs.androidx.compose.ui.test.manifest)
    debugImplementation(libs.androidx.compose.ui.tooling)

    // === NHÓM 1: UI & CẤU TRÚC ĐIỀU HƯỚNG (Bắt buộc cho 3 Tab) ===
    // Thư viện để chuyển trang (Navigation) và tạo Bottom Navigation
    implementation(libs.androidx.navigation.compose)
    // Thư viện quản lý logic (ViewModel) tránh mất data khi xoay màn hình
    implementation(libs.androidx.lifecycle.viewmodel.compose)

    // === NHÓM 2: DỮ LIỆU & FIREBASE (Cho Tab 1 & Tab 2) ===
    // Firebase BoM (Bill of Materials) - Quản lý đồng bộ phiên bản cho mọi dịch vụ Firebase
    implementation(platform(libs.firebase.bom))
    // Xác thực người dùng (Đăng nhập/Đăng ký)
    implementation(libs.google.firebase.auth)
    // Cơ sở dữ liệu Cloud Firestore (Lưu chỉ số sức khỏe, nhật ký)
    implementation(libs.google.firebase.firestore)
    // DataStore (Lưu các cấu hình nhỏ dưới máy như trạng thái đã đăng nhập)
    implementation(libs.androidx.datastore.preferences)

    // === NHÓM 3: TÍNH NĂNG "KILLER" & MỞ RỘNG (Cho Tab 3 & Thống kê) ===
    // Google Generative AI SDK (Gemini) - Làm Trợ lý tâm lý AI
    implementation(libs.generativeai)
    // Coil - Hỗ trợ tải và hiển thị ảnh từ Internet siêu mượt
    implementation(libs.coil.compose)
    // Vico - Vẽ biểu đồ thống kê cực đẹp cho ứng dụng Compose (Tùy chọn)
    implementation(libs.vico.compose.m3)
    implementation(libs.vico.core)
    //noinspection UseTomlInstead,UseTomlInstead
    implementation(libs.androidx.compose.material.icons.extended)
}