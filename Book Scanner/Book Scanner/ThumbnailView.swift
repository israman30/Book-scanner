//
//  ThumbnailView.swift
//  Book Scanner
//
//  Created by Israel Manzo on 2/26/26.
//
import SwiftUI

struct ThumbnailView: View {
    let url: URL
    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .empty:
                ProgressView()
                    .progressViewStyle(.circular)
            case .success(let image):
                image
                    .resizable()
                    .scaledToFit()
            case .failure:
                EmptyView()
            @unknown default:
                EmptyView()
            }
        }
    }
}

#Preview {
    ThumbnailView(url: URL(string: ""))
}
