import SwiftUI

/// Why something did not load, in the terms the error page uses. Each case
/// has one plain sentence, so iOS's own error text never reaches the screen.
enum LoadFailure: Equatable {
    case offline, unavailable, notFound, other

    /// `nil` for cancellation: a load abandoned by navigation is not a failure.
    init?(_ error: any Error) {
        if error is CancellationError { return nil }
        switch error as? WikipediaError {
        case .offline:
            self = .offline
        case .timedOut:
            self = .unavailable
        case .httpStatus(404):
            self = .notFound
        case .httpStatus(let code) where code == 429 || code >= 500:
            self = .unavailable
        default:
            self = .other
        }
    }

    var reason: String {
        switch self {
        case .offline: "You're offline. This loads by itself once you're back."
        case .unavailable: "Wikipedia isn't answering right now."
        case .notFound: "Wikipedia has no article by this name."
        case .other: "Something went wrong on the way from Wikipedia."
        }
    }
}

/// V for Wikipedia's error page: say what did not load, why in plain words,
/// and offer one way on. A failure from being offline retries by itself.
struct LoadFailureView: View {
    let headline: String
    let failure: LoadFailure
    let retry: () -> Void
    /// Offered instead of Try again when the article does not exist.
    var search: (() -> Void)?
    /// Over a map there is no room for the picture.
    var isCompact = false

    @Environment(\.folioTheme) private var theme
    private let connectivity = Connectivity.shared

    var body: some View {
        VStack(spacing: isCompact ? 10 : 18) {
            Text(headline)
                .font(.headline)
                .foregroundStyle(.secondary)
            if !isCompact {
                ParagraphMark(unit: 1.5, isWordMissing: true)
                    .padding(.vertical, 6)
                    .accessibilityHidden(true)
            }
            Text(failure.reason)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button(action: action.run) {
                Text(action.label)
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(theme.barBackground, in: shape)
                    .overlay(shape.stroke(theme.palette.hairlineColor, lineWidth: 0.75))
            }
            .buttonStyle(.plain)
            .foregroundStyle(theme.palette.foregroundColor)
        }
        .frame(maxWidth: 320)
        .padding(.horizontal, 24)
        .onChange(of: connectivity.isOnline) { _, isOnline in
            if isOnline && failure == .offline { retry() }
        }
    }

    private var shape: RoundedRectangle { RoundedRectangle(cornerRadius: 10, style: .continuous) }

    private var action: (label: String, run: () -> Void) {
        if failure == .notFound, let search { ("Search for it", search) } else { ("Try again", retry) }
    }
}
