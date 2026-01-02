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

    // 创建全局的 LanguageManager 实例
    @StateObject private var languageManager = LanguageManager.shared

    var body: some Scene {
        WindowGroup {
            RootContentView()
                .environmentObject(authManager)
                .environmentObject(languageManager)
                .environment(\.locale, languageManager.currentLanguage.languageCode.map { Locale(identifier: $0) } ?? Locale.current)
        }
    }
}

/// 根内容视图 - 启动页 → 认证页 → 主页
struct RootContentView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var languageManager: LanguageManager

    /// 启动页是否完成
    @State private var splashFinished = false

    var body: some View {
        ZStack {
            if !splashFinished {
                // 第一阶段：显示启动页（带认证检查）
                SplashView(isFinished: $splashFinished)
                    .transition(.opacity)
            } else {
                // 第二阶段：根据认证状态显示页面
                if authManager.isAuthenticated {
                    // 已登录 - 显示主应用（Tab 导航）
                    MainTabView()
                        .transition(.opacity)
                } else {
                    // 未登录 - 显示认证页面
                    AuthView(authManager: authManager)
                        .transition(.opacity)
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: splashFinished)
        .animation(.easeInOut(duration: 0.3), value: authManager.isAuthenticated)
        .id(languageManager.refreshID) // 使用 refreshID 强制刷新整个视图树
    }
}
