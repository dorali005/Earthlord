//
//  AuthView.swift
//  Earthlord
//
//  Created by qqyl on 2025/12/27.
//

import SwiftUI

struct AuthView: View {
    // MARK: - State Objects & Properties

    @StateObject private var authManager: AuthManager

    // Tab 切换状态
    @State private var selectedTab: AuthTab = .login

    // 登录表单
    @State private var loginEmail = ""
    @State private var loginPassword = ""

    // 注册表单
    @State private var registerEmail = ""
    @State private var registerOTP = ""
    @State private var registerPassword = ""
    @State private var registerConfirmPassword = ""
    @State private var registerStep = 1 // 1: 邮箱, 2: 验证码, 3: 密码

    // 忘记密码弹窗
    @State private var showForgotPassword = false
    @State private var resetEmail = ""
    @State private var resetOTP = ""
    @State private var resetPassword = ""
    @State private var resetConfirmPassword = ""
    @State private var resetStep = 1 // 1: 邮箱, 2: 验证码, 3: 新密码

    // 倒计时
    @State private var otpCountdown = 0
    @State private var timer: Timer? = nil

    // Toast 提示
    @State private var showToast = false
    @State private var toastMessage = ""

    // MARK: - Initialization

    init(authManager: AuthManager) {
        _authManager = StateObject(wrappedValue: authManager)
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // 深色渐变背景
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.1, green: 0.1, blue: 0.2),
                    Color(red: 0.05, green: 0.05, blue: 0.15)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 30) {
                    // Logo 和标题
                    VStack(spacing: 16) {
                        Image(systemName: "globe.asia.australia.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)
                            .padding(.top, 60)

                        Text("地球新主")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.bottom, 20)

                    // Tab 切换
                    tabSelector
                        .padding(.horizontal, 40)

                    // 错误提示
                    if let errorMessage = authManager.errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal, 40)
                            .multilineTextAlignment(.center)
                    }

                    // 内容区域
                    if selectedTab == .login {
                        loginView
                    } else {
                        registerView
                    }

                    // 第三方登录
                    thirdPartyLoginSection
                        .padding(.top, 20)
                }
                .padding(.bottom, 40)
            }

            // 加载指示器
            if authManager.isLoading {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()

                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            }

            // Toast 提示
            if showToast {
                VStack {
                    Spacer()
                    Text(toastMessage)
                        .font(.body)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(10)
                        .padding(.bottom, 50)
                }
                .transition(.move(edge: .bottom))
            }
        }
        .sheet(isPresented: $showForgotPassword) {
            forgotPasswordSheet
        }
        .onChange(of: authManager.otpVerified) { oldValue, newValue in
            // 注册流程：验证成功后跳转到第三步
            if newValue && selectedTab == .register {
                registerStep = 3
            }
        }
    }

    // MARK: - Tab Selector

    private var tabSelector: some View {
        HStack(spacing: 0) {
            // 登录 Tab
            Button(action: {
                withAnimation {
                    selectedTab = .login
                    authManager.clearError()
                }
            }) {
                Text("登录")
                    .font(.headline)
                    .foregroundColor(selectedTab == .login ? .white : .gray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        selectedTab == .login ?
                        Color.blue.opacity(0.3) : Color.clear
                    )
            }

            // 注册 Tab
            Button(action: {
                withAnimation {
                    selectedTab = .register
                    authManager.clearError()
                    registerStep = 1
                }
            }) {
                Text("注册")
                    .font(.headline)
                    .foregroundColor(selectedTab == .register ? .white : .gray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        selectedTab == .register ?
                        Color.blue.opacity(0.3) : Color.clear
                    )
            }
        }
        .background(Color.white.opacity(0.1))
        .cornerRadius(10)
    }

    // MARK: - Login View

    private var loginView: some View {
        VStack(spacing: 20) {
            // 邮箱输入
            CustomTextField(
                icon: "envelope.fill",
                placeholder: "邮箱",
                text: $loginEmail
            )
            .textInputAutocapitalization(.never)
            .keyboardType(.emailAddress)

            // 密码输入
            CustomSecureField(
                icon: "lock.fill",
                placeholder: "密码",
                text: $loginPassword
            )

            // 忘记密码链接
            HStack {
                Spacer()
                Button(action: {
                    showForgotPassword = true
                }) {
                    Text("忘记密码？")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 40)

            // 登录按钮
            Button(action: {
                Task {
                    await authManager.signIn(email: loginEmail, password: loginPassword)
                }
            }) {
                Text("登录")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .disabled(loginEmail.isEmpty || loginPassword.isEmpty)
            .opacity(loginEmail.isEmpty || loginPassword.isEmpty ? 0.6 : 1.0)
            .padding(.horizontal, 40)
            .padding(.top, 10)
        }
    }

    // MARK: - Register View

    private var registerView: some View {
        VStack(spacing: 20) {
            // 根据步骤显示不同内容
            if registerStep == 1 {
                registerStep1
            } else if registerStep == 2 {
                registerStep2
            } else {
                registerStep3
            }
        }
    }

    // 注册第一步：邮箱输入
    private var registerStep1: some View {
        VStack(spacing: 20) {
            Text("输入您的邮箱")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.top, 10)

            CustomTextField(
                icon: "envelope.fill",
                placeholder: "邮箱",
                text: $registerEmail
            )
            .textInputAutocapitalization(.never)
            .keyboardType(.emailAddress)

            Button(action: {
                Task {
                    await authManager.sendRegisterOTP(email: registerEmail)
                    if authManager.otpSent {
                        registerStep = 2
                        startOTPCountdown()
                    }
                }
            }) {
                Text("发送验证码")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .disabled(registerEmail.isEmpty || !isValidEmail(registerEmail))
            .opacity(registerEmail.isEmpty || !isValidEmail(registerEmail) ? 0.6 : 1.0)
            .padding(.horizontal, 40)
        }
    }

    // 注册第二步：验证码输入
    private var registerStep2: some View {
        VStack(spacing: 20) {
            Text("验证码已发送至")
                .font(.headline)
                .foregroundColor(.white)

            Text(registerEmail)
                .font(.caption)
                .foregroundColor(.gray)

            CustomTextField(
                icon: "number",
                placeholder: "请输入6位验证码",
                text: $registerOTP
            )
            .keyboardType(.numberPad)

            // 重发倒计时
            if otpCountdown > 0 {
                Text("重新发送 (\(otpCountdown)s)")
                    .font(.caption)
                    .foregroundColor(.gray)
            } else {
                Button(action: {
                    Task {
                        await authManager.sendRegisterOTP(email: registerEmail)
                        if authManager.otpSent {
                            startOTPCountdown()
                        }
                    }
                }) {
                    Text("重新发送验证码")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }

            Button(action: {
                Task {
                    await authManager.verifyRegisterOTP(email: registerEmail, code: registerOTP)
                    // 验证成功后会自动跳转到第三步（通过 onChange 监听）
                }
            }) {
                Text("验证")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .disabled(registerOTP.count != 6)
            .opacity(registerOTP.count != 6 ? 0.6 : 1.0)
            .padding(.horizontal, 40)
        }
    }

    // 注册第三步：设置密码
    private var registerStep3: some View {
        VStack(spacing: 20) {
            Text("设置您的密码")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.top, 10)

            Text("密码至少8位，包含字母和数字")
                .font(.caption)
                .foregroundColor(.gray)

            CustomSecureField(
                icon: "lock.fill",
                placeholder: "密码",
                text: $registerPassword
            )

            CustomSecureField(
                icon: "lock.fill",
                placeholder: "确认密码",
                text: $registerConfirmPassword
            )

            // 密码匹配提示
            if !registerConfirmPassword.isEmpty && registerPassword != registerConfirmPassword {
                Text("两次密码不一致")
                    .font(.caption)
                    .foregroundColor(.red)
            }

            Button(action: {
                Task {
                    await authManager.completeRegistration(password: registerPassword)
                    // 成功后 isAuthenticated 会变为 true，自动跳转主页
                }
            }) {
                Text("完成注册")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(12)
            }
            .disabled(!isValidPassword(registerPassword) || registerPassword != registerConfirmPassword)
            .opacity(!isValidPassword(registerPassword) || registerPassword != registerConfirmPassword ? 0.6 : 1.0)
            .padding(.horizontal, 40)
        }
    }

    // MARK: - Forgot Password Sheet

    private var forgotPasswordSheet: some View {
        NavigationView {
            ZStack {
                Color(red: 0.1, green: 0.1, blue: 0.2)
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    if resetStep == 1 {
                        resetPasswordStep1
                    } else if resetStep == 2 {
                        resetPasswordStep2
                    } else {
                        resetPasswordStep3
                    }

                    Spacer()
                }
                .padding(.top, 40)

                if authManager.isLoading {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()

                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
            }
            .navigationTitle("找回密码")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        showForgotPassword = false
                        resetStep = 1
                        resetEmail = ""
                        resetOTP = ""
                        resetPassword = ""
                        resetConfirmPassword = ""
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }

    // 找回密码第一步：邮箱
    private var resetPasswordStep1: some View {
        VStack(spacing: 20) {
            Text("输入您注册时使用的邮箱")
                .font(.headline)
                .foregroundColor(.white)

            CustomTextField(
                icon: "envelope.fill",
                placeholder: "邮箱",
                text: $resetEmail
            )
            .textInputAutocapitalization(.never)
            .keyboardType(.emailAddress)

            if let errorMessage = authManager.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, 40)
            }

            Button(action: {
                Task {
                    await authManager.sendResetOTP(email: resetEmail)
                    if authManager.otpSent {
                        resetStep = 2
                        startOTPCountdown()
                    }
                }
            }) {
                Text("发送验证码")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .disabled(resetEmail.isEmpty || !isValidEmail(resetEmail))
            .opacity(resetEmail.isEmpty || !isValidEmail(resetEmail) ? 0.6 : 1.0)
            .padding(.horizontal, 40)
        }
    }

    // 找回密码第二步：验证码
    private var resetPasswordStep2: some View {
        VStack(spacing: 20) {
            Text("验证码已发送至")
                .font(.headline)
                .foregroundColor(.white)

            Text(resetEmail)
                .font(.caption)
                .foregroundColor(.gray)

            CustomTextField(
                icon: "number",
                placeholder: "请输入6位验证码",
                text: $resetOTP
            )
            .keyboardType(.numberPad)

            if otpCountdown > 0 {
                Text("重新发送 (\(otpCountdown)s)")
                    .font(.caption)
                    .foregroundColor(.gray)
            } else {
                Button(action: {
                    Task {
                        await authManager.sendResetOTP(email: resetEmail)
                        if authManager.otpSent {
                            startOTPCountdown()
                        }
                    }
                }) {
                    Text("重新发送验证码")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }

            if let errorMessage = authManager.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, 40)
            }

            Button(action: {
                Task {
                    await authManager.verifyResetOTP(email: resetEmail, code: resetOTP)
                    if authManager.otpVerified {
                        resetStep = 3
                    }
                }
            }) {
                Text("验证")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .disabled(resetOTP.count != 6)
            .opacity(resetOTP.count != 6 ? 0.6 : 1.0)
            .padding(.horizontal, 40)
        }
    }

    // 找回密码第三步：新密码
    private var resetPasswordStep3: some View {
        VStack(spacing: 20) {
            Text("设置新密码")
                .font(.headline)
                .foregroundColor(.white)

            Text("密码至少8位，包含字母和数字")
                .font(.caption)
                .foregroundColor(.gray)

            CustomSecureField(
                icon: "lock.fill",
                placeholder: "新密码",
                text: $resetPassword
            )

            CustomSecureField(
                icon: "lock.fill",
                placeholder: "确认新密码",
                text: $resetConfirmPassword
            )

            if !resetConfirmPassword.isEmpty && resetPassword != resetConfirmPassword {
                Text("两次密码不一致")
                    .font(.caption)
                    .foregroundColor(.red)
            }

            if let errorMessage = authManager.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, 40)
            }

            Button(action: {
                Task {
                    await authManager.resetPassword(newPassword: resetPassword)
                    if authManager.isAuthenticated {
                        showForgotPassword = false
                        resetStep = 1
                    }
                }
            }) {
                Text("重置密码")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(12)
            }
            .disabled(!isValidPassword(resetPassword) || resetPassword != resetConfirmPassword)
            .opacity(!isValidPassword(resetPassword) || resetPassword != resetConfirmPassword ? 0.6 : 1.0)
            .padding(.horizontal, 40)
        }
    }

    // MARK: - Third Party Login Section

    private var thirdPartyLoginSection: some View {
        VStack(spacing: 20) {
            // 分隔线
            HStack {
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(height: 1)

                Text("或者使用以下方式登录")
                    .font(.caption)
                    .foregroundColor(.gray)

                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(height: 1)
            }
            .padding(.horizontal, 40)

            // Apple 登录按钮
            Button(action: {
                showToastMessage("Apple 登录即将开放")
            }) {
                HStack {
                    Image(systemName: "apple.logo")
                        .font(.title2)
                    Text("使用 Apple 登录")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.black)
                .cornerRadius(12)
            }
            .padding(.horizontal, 40)

            // Google 登录按钮
            Button(action: {
                showToastMessage("Google 登录即将开放")
            }) {
                HStack {
                    Image(systemName: "g.circle.fill")
                        .font(.title2)
                    Text("使用 Google 登录")
                        .font(.headline)
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white)
                .cornerRadius(12)
            }
            .padding(.horizontal, 40)
        }
    }

    // MARK: - Helper Methods

    /// 启动 OTP 倒计时（60秒）
    private func startOTPCountdown() {
        otpCountdown = 60
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if otpCountdown > 0 {
                otpCountdown -= 1
            } else {
                timer?.invalidate()
            }
        }
    }

    /// 验证邮箱格式
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    /// 验证密码强度（至少8位，包含字母和数字）
    private func isValidPassword(_ password: String) -> Bool {
        guard password.count >= 8 else { return false }
        let hasLetter = password.rangeOfCharacter(from: .letters) != nil
        let hasNumber = password.rangeOfCharacter(from: .decimalDigits) != nil
        return hasLetter && hasNumber
    }

    /// 显示 Toast 消息
    private func showToastMessage(_ message: String) {
        toastMessage = message
        withAnimation {
            showToast = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showToast = false
            }
        }
    }
}

// MARK: - Supporting Types

enum AuthTab {
    case login
    case register
}

// MARK: - Custom TextField

struct CustomTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.gray)
                .frame(width: 30)

            TextField(placeholder, text: $text)
                .foregroundColor(.white)
                .autocapitalization(.none)
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(10)
        .padding(.horizontal, 40)
    }
}

// MARK: - Custom SecureField

struct CustomSecureField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.gray)
                .frame(width: 30)

            SecureField(placeholder, text: $text)
                .foregroundColor(.white)
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(10)
        .padding(.horizontal, 40)
    }
}

// MARK: - Preview

#Preview {
    AuthView(authManager: AuthManager(supabase: supabase))
}
