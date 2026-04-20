import SwiftUI

struct OnboardingView: View {
    let onComplete: () -> Void

    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            symbol: "map.circle.fill",
            title: "Find free events near you",
            body: "Discover run clubs, book meetups, and community gatherings happening around you — most of them free."
        ),
        OnboardingPage(
            symbol: "camera.viewfinder",
            title: "Snap a poster, create an event",
            body: "See a cool flyer? Snap a photo. Loop reads the details and posts it in seconds."
        ),
        OnboardingPage(
            symbol: "checkmark.circle.fill",
            title: "Tap 'I'm Going' without the awkward",
            body: "RSVP casually. No tickets, no commitment — just a heads-up that you might show up."
        ),
    ]

    var body: some View {
        ZStack(alignment: .topTrailing) {
            TabView(selection: $currentPage) {
                ForEach(pages.indices, id: \.self) { index in
                    pageView(pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            .ignoresSafeArea(edges: .bottom)

            Button("Skip") { onComplete() }
                .font(.body.weight(.medium))
                .padding()
        }
        .overlay(alignment: .bottom) {
            primaryButton
                .padding(.horizontal, 24)
                .padding(.bottom, 52)
        }
    }

    private func pageView(_ page: OnboardingPage) -> some View {
        VStack(spacing: 0) {
            Spacer()
            Image(systemName: page.symbol)
                .font(.system(size: 100))
                .foregroundStyle(.blue)
            Spacer().frame(height: 24)
            Text(page.title)
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
            Spacer().frame(height: 16)
            Text(page.body)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
            Spacer()
        }
    }

    private var primaryButton: some View {
        Button {
            if currentPage < pages.count - 1 {
                withAnimation { currentPage += 1 }
            } else {
                onComplete()
            }
        } label: {
            Text(currentPage < pages.count - 1 ? "Continue" : "Get Started")
                .font(.body.weight(.semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.blue)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}

private struct OnboardingPage {
    let symbol: String
    let title: String
    let body: String
}
