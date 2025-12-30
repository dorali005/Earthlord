//
//  AuthManager.swift
//  Earthlord
//
//  Created by qqyl on 2025/12/27.
//

import SwiftUI
import Supabase
import Combine

/// 认证管理器 - 处理用户注册、登录、密码管理等认证流程
@MainActor
class AuthManager: ObservableObject {

    // MARK: - Published Properties（发布属性）

    /// 用户是否已认证（已登录且完成所有流程）
    @Published var isAuthenticated: Bool = false

    /// 是否需要设置密码（OTP 验证后需要设置密码）
    @Published var needsPasswordSetup: Bool = false

    /// 当前登录用户
    @Published var currentUser: User? = nil

    /// 是否正在加载
    @Published var isLoading: Bool = false

    /// 错误消息
    @Published var errorMessage: String? = nil

    /// OTP 验证码是否已发送
    @Published var otpSent: Bool = false

    /// OTP 验证码是否已验证（验证后等待设置密码）
    @Published var otpVerified: Bool = false

    /// 会话是否过期（用于显示提示信息）
    @Published var sessionExpired: Bool = false

    // MARK: - Private Properties

    /// Supabase 客户端实例
    private let supabase: SupabaseClient

    /// 认证状态监听任务
    private var authStateTask: Task<Void, Never>?

    // MARK: - Initialization

    init(supabase: SupabaseClient) {
        self.supabase = supabase
        // 启动认证状态监听
        setupAuthStateListener()
    }

    deinit {
        // 取消监听任务
        authStateTask?.cancel()
    }

    // MARK: - 认证状态监听

    /// 设置认证状态监听器
    private func setupAuthStateListener() {
        authStateTask = Task { @MainActor in
            for await state in await supabase.auth.authStateChanges {
                // 监听认证状态变化
                switch state.event {
                case .signedIn:
                    // 用户登录
                    currentUser = state.session?.user
                    // 清除会话过期标志
                    sessionExpired = false
                    // 只有在不需要设置密码时才标记为已认证
                    if !needsPasswordSetup {
                        isAuthenticated = true
                    }
                    print("🔐 用户已登录：\(state.session?.user.email ?? "未知")")

                case .signedOut:
                    // 用户登出
                    let wasAuthenticated = isAuthenticated
                    currentUser = nil
                    isAuthenticated = false
                    needsPasswordSetup = false
                    otpVerified = false

                    // 如果之前是已认证状态，且不是主动登出，则标记为会话过期
                    // 主动登出时 isLoading 会是 true（因为 signOut() 方法会设置）
                    if wasAuthenticated && !isLoading {
                        sessionExpired = true
                        print("⏰ 会话已过期")
                    } else {
                        sessionExpired = false
                        print("🔓 用户已登出")
                    }

                case .tokenRefreshed:
                    // Token 刷新成功，清除过期标志
                    currentUser = state.session?.user
                    sessionExpired = false
                    print("🔄 Token 已刷新")

                case .userUpdated:
                    // 用户信息更新
                    currentUser = state.session?.user
                    print("👤 用户信息已更新")

                default:
                    break
                }
            }
        }
    }

    // MARK: - 注册流程方法

    /// 发送注册验证码
    /// - Parameter email: 用户邮箱
    func sendRegisterOTP(email: String) async {
        isLoading = true
        errorMessage = nil
        otpSent = false

        do {
            // 调用 Supabase 发送 OTP，并允许创建新用户
            try await supabase.auth.signInWithOTP(
                email: email,
                shouldCreateUser: true
            )

            // 成功发送
            otpSent = true
            isLoading = false

        } catch {
            // 处理错误
            errorMessage = "发送验证码失败：\(error.localizedDescription)"
            isLoading = false
            otpSent = false
        }
    }

    /// 验证注册 OTP 验证码
    /// - Parameters:
    ///   - email: 用户邮箱
    ///   - code: 6 位验证码
    func verifyRegisterOTP(email: String, code: String) async {
        isLoading = true
        errorMessage = nil

        do {
            // 调用 Supabase 验证 OTP
            let session = try await supabase.auth.verifyOTP(
                email: email,
                token: code,
                type: .email
            )

            // 验证成功，用户已登录但还没设置密码
            currentUser = session.user
            otpVerified = true
            needsPasswordSetup = true
            // 注意：此时 isAuthenticated 保持 false，直到完成密码设置
            isLoading = false

        } catch {
            // 处理错误
            errorMessage = "验证码验证失败：\(error.localizedDescription)"
            isLoading = false
            otpVerified = false
        }
    }

    /// 完成注册（设置密码）
    /// - Parameter password: 用户设置的密码
    func completeRegistration(password: String) async {
        isLoading = true
        errorMessage = nil

        do {
            // 更新用户密码
            let user = try await supabase.auth.update(
                user: UserAttributes(password: password)
            )

            // 注册完成，用户已完全认证
            currentUser = user
            needsPasswordSetup = false
            isAuthenticated = true
            otpVerified = false
            isLoading = false

        } catch {
            // 处理错误
            errorMessage = "设置密码失败：\(error.localizedDescription)"
            isLoading = false
        }
    }

    // MARK: - 登录方法

    /// 使用邮箱和密码登录
    /// - Parameters:
    ///   - email: 用户邮箱
    ///   - password: 用户密码
    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil

        do {
            // 调用 Supabase 登录
            let session = try await supabase.auth.signIn(
                email: email,
                password: password
            )

            // 登录成功
            currentUser = session.user
            isAuthenticated = true
            needsPasswordSetup = false
            isLoading = false

        } catch {
            // 处理错误
            errorMessage = "登录失败：\(error.localizedDescription)"
            isLoading = false
            isAuthenticated = false
        }
    }

    // MARK: - 找回密码流程

    /// 发送密码重置验证码
    /// - Parameter email: 用户邮箱
    func sendResetOTP(email: String) async {
        isLoading = true
        errorMessage = nil
        otpSent = false

        do {
            // 调用 Supabase 发送密码重置邮件
            try await supabase.auth.resetPasswordForEmail(email)

            // 成功发送
            otpSent = true
            isLoading = false

        } catch {
            // 处理错误
            errorMessage = "发送重置验证码失败：\(error.localizedDescription)"
            isLoading = false
            otpSent = false
        }
    }

    /// 验证密码重置 OTP 验证码
    /// - Parameters:
    ///   - email: 用户邮箱
    ///   - code: 6 位验证码
    func verifyResetOTP(email: String, code: String) async {
        isLoading = true
        errorMessage = nil

        do {
            // ⚠️ 注意：密码重置使用 .recovery 类型，不是 .email
            let session = try await supabase.auth.verifyOTP(
                email: email,
                token: code,
                type: .recovery
            )

            // 验证成功，用户已登录，等待设置新密码
            currentUser = session.user
            otpVerified = true
            needsPasswordSetup = true
            isLoading = false

        } catch {
            // 处理错误
            errorMessage = "验证码验证失败：\(error.localizedDescription)"
            isLoading = false
            otpVerified = false
        }
    }

    /// 重置密码（设置新密码）
    /// - Parameter newPassword: 新密码
    func resetPassword(newPassword: String) async {
        isLoading = true
        errorMessage = nil

        do {
            // 更新用户密码
            let user = try await supabase.auth.update(
                user: UserAttributes(password: newPassword)
            )

            // 密码重置完成
            currentUser = user
            needsPasswordSetup = false
            isAuthenticated = true
            otpVerified = false
            isLoading = false

        } catch {
            // 处理错误
            errorMessage = "重置密码失败：\(error.localizedDescription)"
            isLoading = false
        }
    }

    // MARK: - 第三方登录（预留）

    /// Apple 登录
    /// TODO: 实现 Apple 登录功能
    func signInWithApple() async {
        isLoading = true
        errorMessage = nil

        // TODO: 实现 Sign in with Apple
        errorMessage = "Apple 登录功能即将推出"
        isLoading = false
    }

    /// Google 登录
    /// TODO: 实现 Google 登录功能
    func signInWithGoogle() async {
        isLoading = true
        errorMessage = nil

        // TODO: 实现 Sign in with Google
        errorMessage = "Google 登录功能即将推出"
        isLoading = false
    }

    // MARK: - 其他方法

    /// 退出登录
    func signOut() async {
        isLoading = true
        errorMessage = nil

        do {
            // 调用 Supabase 退出登录
            try await supabase.auth.signOut()

            // 清空状态
            currentUser = nil
            isAuthenticated = false
            needsPasswordSetup = false
            otpVerified = false
            otpSent = false
            sessionExpired = false
            isLoading = false

        } catch {
            // 处理错误
            errorMessage = "退出登录失败：\(error.localizedDescription)"
            isLoading = false
        }
    }

    /// 检查当前会话状态
    /// 在应用启动时调用，恢复用户登录状态
    func checkSession() async {
        isLoading = true

        do {
            // 获取当前会话
            let session = try await supabase.auth.session

            // 如果有有效会话，恢复登录状态
            currentUser = session.user
            isAuthenticated = true
            needsPasswordSetup = false
            isLoading = false

        } catch {
            // 没有有效会话或出错，保持未登录状态
            currentUser = nil
            isAuthenticated = false
            needsPasswordSetup = false
            isLoading = false
        }
    }

    // MARK: - Helper Methods

    /// 清空错误消息
    func clearError() {
        errorMessage = nil
    }

    /// 重置所有状态（用于测试或调试）
    func resetAllStates() {
        currentUser = nil
        isAuthenticated = false
        needsPasswordSetup = false
        otpVerified = false
        otpSent = false
        isLoading = false
        errorMessage = nil
    }
}
