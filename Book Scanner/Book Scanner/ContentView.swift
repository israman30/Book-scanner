//
//  ContentView.swift
//  Book Scanner
//
//  Created by Israel Manzo on 2/19/26.
//

import SwiftUI

struct ContentView: View {
    @State private var showScanner = false

    var body: some View {
        VStack {
            Text("Welcome to Book Scanner")
                .font(.title2)
                .padding(.bottom, 16)

            Button {
                showScanner = true
            } label: {
                Label("Scan Now", systemImage: "camera.viewfinder")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 24)
        }
        .padding()
        .fullScreenCover(isPresented: $showScanner) {
            BookScannerView()
        }
    }
}

#Preview {
    ContentView()
}
