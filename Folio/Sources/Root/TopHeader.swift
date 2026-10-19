import SwiftUI
import UIKit

struct TopHeader: View {
    @Binding var searchText: String
    @Binding var selectedTab: ContentView.Tab
    @FocusState.Binding var searchFocused: Bool

    let theme: Theme
    let language: String
    let onLogoTap: () -> Void
    let onLanguageToggle: () -> Void
    let onRandomTap: () -> Void
    let onSettingsTap: () -> Void
    let onReselectTab: (ContentView.Tab) -> Void

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                Button(action: onLogoTap) {
                    ParagraphMark()
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Home")

                SearchBar(text: $searchText, focused: $searchFocused)

                Button(action: onRandomTap) {
                    Image(systemName: "shuffle")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(width: 24, height: 24)
                }
                .accessibilityLabel("Random article")

                Button(action: onLanguageToggle) {
                    Text(language.uppercased())
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(theme.palette.accentColor)
                        .frame(minWidth: 28)
                        .padding(.vertical, 6)
                }
                .accessibilityLabel("Language: \(language.uppercased()). Tap to toggle.")

                Button(action: onSettingsTap) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 17))
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel("Settings")
            }
            .padding(.horizontal, 14)
            .padding(.top, 6)

            TabIconRow(selectedTab: $selectedTab, onReselectTab: onReselectTab)
        }
        .background(theme.barBackground)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(theme.palette.hairlineColor)
                .frame(height: 0.5)
        }
    }
}

/// The app icon's paragraph at header size: one word in the accent among grey
/// ones. Drawn rather than bundled so it takes each theme's colours.
private struct ParagraphMark: View {
    @Environment(\.folioTheme) private var theme

    // In thirds of a point, so every edge lands on a 3x pixel. Each line is
    // its indent and word widths: the first indented, the last short.
    private static let lines: [(indent: CGFloat, words: [CGFloat])] = [
        (9, [18, 26]), (0, [15, 24, 10]), (0, [27, 26]), (0, [18, 12])
    ]
    private static let accent = (line: 1, word: 1)
    private static let stroke: CGFloat = 7, pitch: CGFloat = 14, gap: CGFloat = 4, width: CGFloat = 57

    var body: some View {
        Canvas { context, _ in
            context.scaleBy(x: 1.0 / 3, y: 1.0 / 3)
            for (row, line) in Self.lines.enumerated() {
                var x = line.indent
                for (index, word) in line.words.enumerated() {
                    let rect = CGRect(x: x, y: CGFloat(row) * Self.pitch, width: word, height: Self.stroke)
                    let isAccent = (row, index) == Self.accent
                    context.fill(Path(rect), with: .color(isAccent ? theme.palette.accentColor : theme.palette.secondaryColor.opacity(0.45)))
                    x += word + Self.gap
                }
            }
        }
        .frame(width: Self.width / 3, height: (CGFloat(Self.lines.count - 1) * Self.pitch + Self.stroke) / 3)
    }
}

private struct SearchBar: View {
    @Binding var text: String
    @FocusState.Binding var focused: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
            TextField("Search Wikipedia", text: $text)
                .textFieldStyle(.plain)
                .submitLabel(.search)
                .focused($focused)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            if !text.isEmpty {
                Button {
                    text = ""
                    focused = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.tertiarySystemFill), in: Capsule())
    }
}

private struct TabIconRow: View {
    @Environment(\.folioTheme) private var theme
    @Binding var selectedTab: ContentView.Tab
    let onReselectTab: (ContentView.Tab) -> Void

    var body: some View {
        HStack(spacing: 0) {
            ForEach(ContentView.Tab.allCases, id: \.self) { tab in
                TabIconButton(tab: tab, isSelected: selectedTab == tab) {
                    if selectedTab != tab {
                        selectedTab = tab
                    } else {
                        onReselectTab(tab)
                    }
                }
            }
        }
    }
}

private struct TabIconButton: View {
    @Environment(\.folioTheme) private var theme
    let tab: ContentView.Tab
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: tab.iconName)
                    .font(.system(size: 18, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? theme.palette.accentColor : Color.secondary)
                Rectangle()
                    .fill(isSelected ? theme.palette.accentColor : Color.clear)
                    .frame(height: 2)
                    .padding(.horizontal, 16)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.accessibilityLabel)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
