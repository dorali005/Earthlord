//
//  ProfileTabView.swift
//  Earthlord
//
//  Created by qqyl on 2025/12/24.
//

import SwiftUI
import Supabase

struct ProfileTabView: View {
    /// 认证管理器
    @EnvironmentObject var authManager: AuthManager

    /// 是否显示退出登录确认弹窗
    @State private var showLogoutConfirmation = false

    /// 是否显示删除账户确认弹窗
    @State private var showDeleteAccountAlert = false

    /// 用户输入的确认文本
    @State private var deleteConfirmationText = ""

    /// 是否正在删除账户
    @State private var isDeletingAccount = false

    var body: some View {
        NavigationView {
            ZStack {
                // 背景
                ApocalypseTheme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 30) {
                        // 用户信息卡片
                        userInfoCard

                        // 设置选项
                        settingsSection

                        // 退出登录按钮
                        logoutButton

                        // 删除账户按钮
                        deleteAccountButton

                        // 底部留白
                        Color.clear.frame(height: 30)
                    }
                    .padding(.top, 20)
                }
            }
            .navigationTitle("个人中心")
            .navigationBarTitleDisplayMode(.large)
        }
        .confirmationDialog(
            "确定要退出登录吗？",
            isPresented: $showLogoutConfirmation,
            titleVisibility: .visible
        ) {
            Button("退出登录", role: .destructive) {
                Task {
                    await authManager.signOut()
                }
            }
            Button("取消", role: .cancel) {}
        }
    }

    // MARK: - 用户信息卡片

    private var userInfoCard: some View {
        VStack(spacing: 20) {
            // 头像
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                ApocalypseTheme.primary,
                                ApocalypseTheme.primary.opacity(0.7)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .shadow(color: ApocalypseTheme.primary.opacity(0.3), radius: 10)

                // 用户头像图标
                Image(systemName: "person.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.white)
            }

            // 用户名/邮箱
            VStack(spacing: 8) {
                if let user = authManager.currentUser {
                    // 显示用户邮箱
                    if let email = user.email {
                        Text(email)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(ApocalypseTheme.textPrimary)
                    }

                    // 显示用户 ID
                    Text("ID: \(user.id.uuidString.prefix(8))...")
                        .font(.caption)
                        .foregroundColor(ApocalypseTheme.textSecondary)
                }
            }

            // 用户状态标签
            HStack(spacing: 12) {
                statusBadge(icon: "checkmark.circle.fill", text: "已认证", color: ApocalypseTheme.success)
                statusBadge(icon: "shield.fill", text: "安全", color: ApocalypseTheme.info)
            }
        }
        .padding(.vertical, 30)
        .padding(.horizontal, 20)
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(16)
        .padding(.horizontal, 20)
    }

    // 状态标签
    private func statusBadge(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(color)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(color.opacity(0.15))
        .cornerRadius(8)
    }

    // MARK: - 设置选项

    private var settingsSection: some View {
        VStack(spacing: 0) {
            settingRow(icon: "person.circle", title: "账户设置", showChevron: true) {}
            Divider().padding(.leading, 60)
            settingRow(icon: "bell.badge", title: "通知设置", showChevron: true) {}
            Divider().padding(.leading, 60)
            settingRow(icon: "lock.shield", title: "隐私与安全", showChevron: true) {}
            Divider().padding(.leading, 60)
            settingRow(icon: "questionmark.circle", title: "帮助与支持", showChevron: true) {}
        }
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(16)
        .padding(.horizontal, 20)
    }

    // 设置行
    private func settingRow(icon: String, title: String, showChevron: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(ApocalypseTheme.primary)
                    .frame(width: 30)

                Text(title)
                    .font(.body)
                    .foregroundColor(ApocalypseTheme.textPrimary)

                Spacer()

                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(ApocalypseTheme.textSecondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }

    // MARK: - 退出登录按钮

    private var logoutButton: some View {
        Button(action: {
            showLogoutConfirmation = true
        }) {
            HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.title3)

                Text("退出登录")
                    .font(.headline)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(ApocalypseTheme.danger)
            .cornerRadius(12)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }

    // MARK: - 删除账户按钮

    private var deleteAccountButton: some View {
        Button(action: {
            showDeleteAccountAlert = true
            deleteConfirmationText = ""
        }) {
            HStack {
                Image(systemName: "trash.fill")
                    .font(.title3)

                Text("删除账户")
                    .font(.headline)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    colors: [Color.red.opacity(0.8), Color.red],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.red.opacity(0.5), lineWidth: 1)
            )
        }
        .padding(.horizontal, 20)
        .padding(.top, 5)
        .alert("删除账户", isPresented: $showDeleteAccountAlert) {
            TextField("请输入\"删除\"以确认", text: $deleteConfirmationText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)

            Button("取消", role: .cancel) {
                deleteConfirmationText = ""
            }

            Button("确认删除", role: .destructive) {
                Task {
                    await performDeleteAccount()
                }
            }
            .disabled(deleteConfirmationText != "删除")

        } message: {
            Text("此操作无法撤销！删除账户将永久删除您的所有数据。\n\n请输入\"删除\"以确认此操作。")
        }
        .overlay(
            Group {
                if isDeletingAccount {
                    ZStack {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()

                        VStack(spacing: 20) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))

                            Text("正在删除账户...")
                                .foregroundColor(.white)
                                .font(.headline)
                        }
                        .padding(40)
                        .background(ApocalypseTheme.cardBackground)
                        .cornerRadius(16)
                    }
                }
            }
        )
    }

    // MARK: - 删除账户操作

    /// 执行删除账户操作
    private func performDeleteAccount() async {
        print("🗑️ 用户确认删除账户")
        isDeletingAccount = true

        do {
            print("📞 调用 AuthManager.deleteAccount()")
            try await authManager.deleteAccount()
            print("✅ 账户删除完成，即将返回登录页面")

            // 成功删除后，用户会自动返回登录页面（因为 isAuthenticated 变为 false）
            isDeletingAccount = false
            deleteConfirmationText = ""

        } catch {
            print("❌ 删除账户失败: \(error.localizedDescription)")
            isDeletingAccount = false
            deleteConfirmationText = ""

            // 显示错误信息（可以考虑添加一个错误提示）
        }
    }
}

#Preview {
    ProfileTabView()
        .environmentObject(AuthManager(supabase: supabase))
}
