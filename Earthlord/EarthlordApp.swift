//
//  EarthlordApp.swift
//  Earthlord
//
//  Created by qqyl on 2025/12/23.
//

import SwiftUI
import Supabase

@main
struct EarthlordApp: App {
    // 创建全局的 AuthManager 实例
    @StateObject private var authManager = AuthManager(supabase: supabase)

    var body: some Scene {
        WindowGroup {
            RootContentView()
                .environmentObject(authManager)
                .task {
                    // 应用启动时检查会话状态
                    await authManager.checkSession()
                }
        }
    }
}

/// 根内容视图 - 根据认证状态显示不同页面
struct RootContentView: View {
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        if authManager.isAuthenticated {
            // 已登录 - 显示主页
            ContentView()
        } else {
            // 未登录 - 显示认证页面
            AuthView(authManager: authManager)
        }
    }
}
