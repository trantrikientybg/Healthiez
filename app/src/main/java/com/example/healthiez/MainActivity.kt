package com.example.healthiez // Nhớ giữ nguyên dòng package name của máy bạn

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Person
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            HealthiezApp()
        }
    }
}

@Composable
fun HealthiezApp() {
    val navController = rememberNavController()
    var selectedItem by remember { mutableIntStateOf(1) } // Mặc định mở Tab 2 (Home)

    Scaffold(
        bottomBar = {
            NavigationBar {
                NavigationBarItem(
                    icon = { Icon(Icons.Filled.Favorite, contentDescription = "Thể chất") },
                    label = { Text("Thể chất") },
                    selected = selectedItem == 0,
                    onClick = {
                        selectedItem = 0
                        navController.navigate("physical")
                    }
                )
                NavigationBarItem(
                    icon = { Icon(Icons.Filled.Home, contentDescription = "Tổng thể") },
                    label = { Text("Tổng thể") },
                    selected = selectedItem == 1,
                    onClick = {
                        selectedItem = 1
                        navController.navigate("home")
                    }
                )
                NavigationBarItem(
                    icon = { Icon(Icons.Filled.Person, contentDescription = "Tinh thần") },
                    label = { Text("Tinh thần") },
                    selected = selectedItem == 2,
                    onClick = {
                        selectedItem = 2
                        navController.navigate("mental")
                    }
                )
            }
        }
    ) { innerPadding ->
        // Đây chính là bộ định tuyến (Router) chuyển đổi giữa 3 màn hình
        NavHost(
            navController = navController,
            startDestination = "home",
            modifier = Modifier.padding(innerPadding)
        ) {
            composable("physical") { PhysicalScreenPlaceholder() }
            composable("home") { HomeScreenPlaceholder() }
            composable("mental") { MentalScreenPlaceholder() }
        }
    }
}

// === CÁC PLACEHOLDER (CHỖ TRỐNG ĐỂ CHIA VIỆC) ===

@Composable
fun PhysicalScreenPlaceholder() {
    Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
        Text("TAB 1: THỂ CHẤT\n(Dev 3 sẽ code toàn bộ UI vào file này)")
    }
}

@Composable
fun HomeScreenPlaceholder() {
    Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
        Text("TAB 2: TRANG CHỦ & AVATAR\n(Dev 2 sẽ code toàn bộ UI vào file này)")
    }
}

@Composable
fun MentalScreenPlaceholder() {
    Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
        Text("TAB 3: TINH THẦN & AI CHAT\n(Dev 4 sẽ code toàn bộ UI vào file này)")
    }
}