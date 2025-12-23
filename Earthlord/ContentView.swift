//
//  ContentView.swift
//  Earthlord
//
//  Created by qqyl on 2025/12/23.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
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
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
