//
//  ContentView.swift
//  Earthlord
//
//  Created by qqyl on 2025/12/23.
//

import SwiftUI
import Auth

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        NavigationStack {
            VStack {
                Image(systemName: "globe")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                Text("Hello, world!")

                Spacer()
                    .frame(height: 20)

                // 显示当前用户邮箱
                if let userEmail = authManager.currentUser?.email {
                    Text("已登录：\(userEmail)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Spacer()
                    .frame(height: 50)

                Text("Developed by Youqing Li")
                    .font(.headline)
                    .foregroundColor(.blue)

                Spacer()
                    .frame(height: 20)

                NavigationLink(destination: TestView()) {
                    Text("进入测试页")
                        .font(.body)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(10)
                }

                Spacer()
                    .frame(height: 20)

                NavigationLink(destination: SupabaseTestView()) {
                    Text("Supabase 连接测试")
                        .font(.body)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.orange)
                        .cornerRadius(10)
                }

                Spacer()
                    .frame(height: 20)

                // 退出登录按钮
                Button(action: {
                    Task {
                        await authManager.signOut()
                    }
                }) {
                    Text("退出登录")
                        .font(.body)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(10)
                }
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
}
