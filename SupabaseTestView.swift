//
  //  SupabaseTestView.swift
  //  Earthlord
  //
  //  Created by qqyl on 2025/12/24.
  //

  import SwiftUI
  import Supabase

  // 在 View 外部初始化 Supabase Client
  let supabase = SupabaseClient(
      supabaseURL: URL(string: "https://vbwenhbxnkplsgneairf.supabase.co")!,
      supabaseKey: "sb_publishable_LcvKoizBZh8Wnyy4xsbcWw_JkJzAJ64"
  )

  struct SupabaseTestView: View {
      @State private var isConnected: Bool? = nil
      @State private var debugLog: String = "点击按钮开始测试..."
      @State private var isTesting: Bool = false

      var body: some View {
          VStack(spacing: 30) {
              Text("Supabase 连接测试")
                  .font(.largeTitle)
                  .fontWeight(.bold)
                  .padding(.top, 40)

              ZStack {
                  Circle()
                      .fill(statusColor.opacity(0.2))
                      .frame(width: 100, height: 100)

                  Image(systemName: statusIcon)
                      .font(.system(size: 50))
                      .foregroundColor(statusColor)
              }
              .padding(.vertical, 20)

              ScrollView {
                  Text(debugLog)
                      .font(.system(.body, design: .monospaced))
                      .foregroundColor(.primary)
                      .frame(maxWidth: .infinity, alignment: .leading)
                      .padding()
                      .background(Color.gray.opacity(0.1))
                      .cornerRadius(10)
              }
              .frame(maxHeight: 300)
              .padding(.horizontal)

              Button(action: {
                  testSupabaseConnection()
              }) {
                  HStack {
                      if isTesting {
                          ProgressView()
                              .progressViewStyle(CircularProgressViewStyle(tint: .white))
                              .scaleEffect(0.8)
                      }
                      Text(isTesting ? "测试中..." : "测试连接")
                          .font(.headline)
                  }
                  .foregroundColor(.white)
                  .frame(maxWidth: .infinity)
                  .padding()
                  .background(isTesting ? Color.gray : Color.blue)
                  .cornerRadius(12)
              }
              .disabled(isTesting)
              .padding(.horizontal)

              Spacer()
          }
      }

      private var statusIcon: String {
          if let isConnected = isConnected {
              return isConnected ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
          }
          return "questionmark.circle"
      }

      private var statusColor: Color {
          if let isConnected = isConnected {
              return isConnected ? .green : .red
          }
          return .gray
      }

      private func testSupabaseConnection() {
          isTesting = true
          debugLog = "开始测试连接...\n"
          debugLog += "URL: https://vbwenhbxnkplsgneairf.supabase.co\n"
          debugLog += "------------------------\n"

          Task {
              do {
                  debugLog += "正在发送请求到不存在的表...\n"

                  let _: [String] = try await supabase
                      .from("non_existent_table")
                      .select()
                      .execute()
                      .value

                  await MainActor.run {
                      isConnected = true
                      debugLog += "✅ 连接成功（服务器已响应）\n"
                      debugLog += "意外：查询成功返回，但这不应该发生。"
                      isTesting = false
                  }

              } catch {
                  await MainActor.run {
                      let errorMessage = error.localizedDescription
                      debugLog += "收到错误响应：\n\(errorMessage)\n"
                      debugLog += "------------------------\n"

                      if errorMessage.contains("PGRST") ||
                         errorMessage.contains("PGRST205") ||
                         errorMessage.contains("Could not find the table") ||
                         errorMessage.contains("relation") && errorMessage.contains("does not exist") {
                          isConnected = true
                          debugLog += "✅ 连接成功（服务器已响应）\n"
                          debugLog += "数据库连接正常，表 'non_existent_table' 不存在（符合预期）"

                      } else if errorMessage.contains("hostname") ||
                                errorMessage.contains("URL") ||
                                errorMessage.contains("NSURLErrorDomain") ||
                                errorMessage.contains("network") ||
                                errorMessage.contains("internet") {
                          isConnected = false
                          debugLog += "❌ 连接失败：URL 错误或无网络\n"
                          debugLog += "详细信息：\(errorMessage)"

                      } else {
                          isConnected = false
                          debugLog += "❌ 连接失败：未知错误\n"
                          debugLog += "错误详情：\n\(error)"
                      }

                      isTesting = false
                  }
              }
          }
      }
  }

  #Preview {
      SupabaseTestView()
  }
