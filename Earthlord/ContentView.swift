//
//  ContentView.swift
//  Earthlord
//
//  Created by qqyl on 2025/12/23.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Image(systemName: "globe")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                Text("Hello, world!")

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
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
}
