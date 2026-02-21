//
//  ContentView.swift
//  Book Scanner
//
//  Created by Israel Manzo on 2/19/26.
//

import SwiftUI

/// Entry screen that lets users start a scan or open their saved library.
/// Keeps the list of saved books in memory and routes to scanner/library sheets.
struct ContentView: View {
    @State private var showScanner = false
    @State private var showLibrary = false
    @State private var savedBooks: [SavedBook] = []

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

            Button {
                showLibrary = true
            } label: {
                Label("View Saved Books (\(savedBooks.count))", systemImage: "books.vertical")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.15))
                    .foregroundStyle(.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
        }
        .padding()
        .fullScreenCover(isPresented: $showScanner) {
            BookScannerView(savedBooks: $savedBooks)
        }
        .sheet(isPresented: $showLibrary) {
            SavedBooksView(savedBooks: $savedBooks)
        }
    }
}

#Preview {
    ContentView()
}
