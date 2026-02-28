//
//  OnboardingCarouselView.swift
//  Book Scanner
//
//  Onboarding carousel shown once to new users with brief app instructions.
//

import SwiftUI

struct OnboardingPage: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let subtitle: String
}

struct OnboardingCarouselView: View {
    var onDismiss: () -> Void

    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "book.closed.fill",
            title: "Welcome to Book Scanner",
            subtitle: "Build your personal book library by scanning barcodes, browsing by subject, and saving your favorites."
        ),
        OnboardingPage(
            icon: "camera.viewfinder",
            title: "Scan Book Barcodes",
            subtitle: "Tap \"Scan Now\" to open the camera. Align a book's barcode or QR code in the frame to look up book details instantly."
        ),
        OnboardingPage(
            icon: "tag.fill",
            title: "Browse by Subject",
            subtitle: "Use \"Browse Books\" to search by ISBN, author, title, or subject. Discover new reads from the Open Library catalog."
        ),
        OnboardingPage(
            icon: "books.vertical.fill",
            title: "Save & Organize",
            subtitle: "Add books to your library and access them anytime. Edit details, share your list, or browse your collection by subject."
        )
    ]

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                        onboardingPageView(page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentPage)

                pageIndicator
                    .padding(.top, 24)

                dismissButton
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
            }

            Button {
                onDismiss()
            } label: {
                Text("Skip")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
            }
            .padding(.top, 12)
            .padding(.trailing, 8)
            .accessibilityLabel("Skip onboarding")
            .accessibilityHint("Dismisses the onboarding and goes to the main screen")
        }
        .background(Color(.systemGroupedBackground))
    }

    private func onboardingPageView(_ page: OnboardingPage) -> some View {
        ScrollView {
            VStack(spacing: 28) {
                Spacer(minLength: 60)

                Image(systemName: page.icon)
                    .font(.system(size: 72))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.accentColor, Color.accentColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .symbolRenderingMode(.hierarchical)

                VStack(spacing: 12) {
                    Text(page.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text(page.subtitle)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)

                Spacer(minLength: 40)
            }
        }
        .scrollIndicators(.hidden)
    }

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<pages.count, id: \.self) { index in
                Capsule()
                    .fill(index == currentPage ? Color.accentColor : Color.primary.opacity(0.2))
                    .frame(width: index == currentPage ? 20 : 8, height: 8)
                    .animation(.easeInOut(duration: 0.25), value: currentPage)
            }
        }
    }

    private var dismissButton: some View {
        Button {
            if currentPage == pages.count - 1 {
                onDismiss()
            } else {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentPage += 1
                }
            }
        } label: {
            Text(currentPage == pages.count - 1 ? "Get Started" : "Continue")
                .font(.headline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.accentColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    OnboardingCarouselView(onDismiss: {})
}
