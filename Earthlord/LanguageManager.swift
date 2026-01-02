//
//  LanguageManager.swift
//  Earthlord
//
//  语言管理器：管理应用内语言切换
//

import SwiftUI
import Combine

/// 语言选项
enum AppLanguage: String, CaseIterable {
    case system = "system"      // 跟随系统
    case chinese = "zh-Hans"    // 简体中文
    case english = "en"         // English

    /// 显示名称
    var displayName: String {
        switch self {
        case .system:
            return NSLocalizedString("跟随系统", comment: "")
        case .chinese:
            return "简体中文"
        case .english:
            return "English"
        }
    }

    /// 获取对应的语言代码
    var languageCode: String? {
        switch self {
        case .system:
            return nil // nil 表示使用系统语言
        case .chinese:
            return "zh-Hans"
        case .english:
            return "en"
        }
    }
}

/// 语言管理器
class LanguageManager: ObservableObject {
    static let shared = LanguageManager()

    /// 当前选择的语言
    @Published var currentLanguage: AppLanguage {
        didSet {
            saveLanguage()
            applyLanguage()
        }
    }

    /// 用于强制刷新 UI 的 ID
    @Published var refreshID = UUID()

    /// UserDefaults 存储 key
    private let languageKey = "app_language"

    /// 当前 Bundle（用于获取本地化字符串）
    private var currentBundle: Bundle = Bundle.main

    private init() {
        // 从 UserDefaults 读取保存的语言设置
        if let savedLanguage = UserDefaults.standard.string(forKey: languageKey),
           let language = AppLanguage(rawValue: savedLanguage) {
            self.currentLanguage = language
        } else {
            self.currentLanguage = .system
        }

        applyLanguage()
    }

    /// 保存语言设置到 UserDefaults
    private func saveLanguage() {
        UserDefaults.standard.set(currentLanguage.rawValue, forKey: languageKey)
    }

    /// 应用语言设置
    private func applyLanguage() {
        if let languageCode = currentLanguage.languageCode {
            // 设置特定语言
            UserDefaults.standard.set([languageCode], forKey: "AppleLanguages")

            // 更新 Bundle 以使用特定语言
            if let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
               let bundle = Bundle(path: path) {
                currentBundle = bundle
            } else {
                currentBundle = Bundle.main
            }
        } else {
            // 跟随系统，移除自定义设置
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
            currentBundle = Bundle.main
        }

        UserDefaults.standard.synchronize()

        // 更新 refreshID 以触发 UI 刷新
        DispatchQueue.main.async {
            self.refreshID = UUID()
        }
    }

    /// 切换语言
    func setLanguage(_ language: AppLanguage) {
        currentLanguage = language
    }

    /// 获取本地化字符串
    func localizedString(_ key: String) -> String {
        return currentBundle.localizedString(forKey: key, value: nil, table: nil)
    }
}

/// String 扩展：方便获取本地化字符串
extension String {
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
}
