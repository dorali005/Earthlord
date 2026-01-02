//
//  LanguageSelectionView.swift
//  Earthlord
//
//  语言选择视图
//

import SwiftUI

struct LanguageSelectionView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var languageManager: LanguageManager

    var body: some View {
        NavigationView {
            ZStack {
                // 背景
                ApocalypseTheme.background
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // 语言选项列表
                    ForEach(AppLanguage.allCases, id: \.self) { language in
                        languageOptionRow(language: language)

                        if language != AppLanguage.allCases.last {
                            Divider()
                                .padding(.leading, 60)
                        }
                    }
                }
                .background(ApocalypseTheme.cardBackground)
                .cornerRadius(16)
                .padding(.horizontal, 20)
                .padding(.top, 20)

                Spacer()
            }
            .navigationTitle("语言设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                    .foregroundColor(ApocalypseTheme.primary)
                }
            }
        }
    }

    // MARK: - 语言选项行

    private func languageOptionRow(language: AppLanguage) -> some View {
        Button(action: {
            languageManager.setLanguage(language)
            // 延迟关闭，让用户看到选中效果
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                dismiss()
            }
        }) {
            HStack(spacing: 16) {
                // 语言图标
                Image(systemName: "globe")
                    .font(.title3)
                    .foregroundColor(ApocalypseTheme.primary)
                    .frame(width: 30)

                // 语言名称
                VStack(alignment: .leading, spacing: 4) {
                    Text(language.displayName)
                        .font(.body)
                        .foregroundColor(ApocalypseTheme.textPrimary)

                    if language == .system {
                        Text("当前语言")
                            .font(.caption)
                            .foregroundColor(ApocalypseTheme.textSecondary)
                    }
                }

                Spacer()

                // 选中标记
                if languageManager.currentLanguage == language {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(ApocalypseTheme.primary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }
}

#Preview {
    LanguageSelectionView(languageManager: LanguageManager.shared)
}
