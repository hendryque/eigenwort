import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.folioTheme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var settingsList: [AppSettings]
    @Query private var history: [HistoryEntry]

    var body: some View {
        NavigationStack {
            Form {
                Section("Wikipedia") {
                    Picker("Default language", selection: languageBinding) {
                        Text("English").tag("en")
                        Text("Deutsch").tag("de")
                    }
                }

                Section {
                    VStack(alignment: .leading, spacing: 14) {
                        ThemePickerRow(selection: themeEnumBinding)
                        Text(themeDescription)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .transition(.opacity)
                            .id(currentTheme)
                    }
                    .padding(.vertical, 4)

                    HStack {
                        Text("Font size")
                        Spacer()
                        Slider(
                            value: fontScaleBinding,
                            in: 0.85...1.6,
                            step: 0.05
                        ) {
                            Text("Font size")
                        } minimumValueLabel: {
                            Text("A").font(.caption)
                        } maximumValueLabel: {
                            Text("A").font(.title3)
                        }
                        .frame(width: 200)
                    }
                } header: {
                    Text("Appearance")
                }

                Section("Reading history") {
                    Button(role: .destructive) {
                        clearHistory()
                    } label: {
                        Text("Clear history (\(history.count))")
                    }
                    .disabled(history.isEmpty)
                }

                Section("About") {
                    NavigationLink("About Eigenwort") {
                        AboutView()
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(theme.paper)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        // The sheet keeps the scheme it opened with, so picking a theme here
        // left Dark with white rows. The resolved theme always names one.
        .preferredColorScheme(theme.colorScheme)
    }

    private var settings: AppSettings? { settingsList.first }
    private var currentTheme: Theme {
        Theme(rawValue: settings?.theme ?? Theme.system.rawValue) ?? .system
    }

    private var themeDescription: String {
        switch currentTheme {
        case .system: "Eigenwort follows your iPhone's appearance setting — light during the day, dark at night."
        case .light: "Pure white background. Maximum contrast for daytime reading."
        case .sepia: "Warm parchment background. Easier on the eyes for long sessions."
        case .dark: "Dim background. Best for low-light and night reading."
        case .debug: "Newsprint and one spot colour. A tribute to De:Bug, the Berlin Magazin für elektronische Lebensaspekte (1997–2014)."
        }
    }

    private var languageBinding: Binding<String> {
        Binding(
            get: { settings?.defaultLanguage ?? "en" },
            set: { newValue in
                settings?.defaultLanguage = newValue
                try? modelContext.save()
            }
        )
    }

    private var themeEnumBinding: Binding<Theme> {
        Binding(
            get: { currentTheme },
            set: { newValue in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                    settings?.theme = newValue.rawValue
                }
                try? modelContext.save()
            }
        )
    }

    private var fontScaleBinding: Binding<Double> {
        Binding(
            get: { settings?.fontScale ?? 1.0 },
            set: { newValue in
                settings?.fontScale = newValue
                try? modelContext.save()
            }
        )
    }

    private func clearHistory() {
        for entry in history {
            modelContext.delete(entry)
        }
        try? modelContext.save()
    }
}

// MARK: - Theme picker

private struct ThemePickerRow: View {
    @Binding var selection: Theme

    var body: some View {
        HStack(spacing: 12) {
            ForEach(Theme.allCases) { theme in
                ThemeCard(theme: theme, isSelected: selection == theme) {
                    if selection != theme {
                        selection = theme
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

private struct ThemeCard: View {
    let theme: Theme
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                ThemePreview(theme: theme)
                    .aspectRatio(3.0 / 4.0, contentMode: .fit)
                    .overlay {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(
                                isSelected ? theme.palette.accentColor : Color(.separator),
                                lineWidth: isSelected ? 2.5 : 0.5
                            )
                    }
                    .overlay(alignment: .topTrailing) {
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18))
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.white, theme.palette.accentColor)
                                .padding(4)
                        }
                    }

                Text(theme.displayName)
                    .font(.caption.weight(isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? theme.palette.accentColor : .primary)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Theme: \(theme.displayName)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct ThemePreview: View {
    let theme: Theme

    var body: some View {
        Group {
            if theme == .system {
                // Auto is the device's choice, so it shows both halves of one page.
                ThemeMockup(palette: .light)
                    .overlay {
                        ThemeMockup(palette: .dark)
                            .mask { HStack(spacing: 0) { Color.clear; Color.black } }
                    }
            } else {
                ThemeMockup(palette: theme.palette)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

/// A page in miniature: a title, text, one link. Line lengths are fractions
/// of the card so five cards fit across even the mini.
private struct ThemeMockup: View {
    let palette: Palette

    private enum Ink { case title, text, link }

    private static let lines: [(length: CGFloat, ink: Ink)] = [
        (0.8, .title), (1, .text), (1, .text), (0.6, .link), (1, .text), (0.7, .text)
    ]

    var body: some View {
        GeometryReader { proxy in
            VStack(alignment: .leading, spacing: 3) {
                ForEach(Self.lines.indices, id: \.self) { index in
                    let line = Self.lines[index]
                    Capsule()
                        .fill(color(line.ink))
                        .frame(width: proxy.size.width * line.length, height: line.ink == .title ? 4 : 2)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 10)
        .background(palette.backgroundColor)
    }

    private func color(_ ink: Ink) -> Color {
        switch ink {
        case .title: palette.foregroundColor
        case .text: palette.foregroundColor.opacity(0.55)
        case .link: Color(rgb: palette.link)
        }
    }
}

// MARK: - About

struct AboutView: View {
    var body: some View {
        List {
            Section {
                LabeledContent("Name", value: "Eigenwort")
                LabeledContent("Version", value: appVersion)
                LabeledContent("Built on", value: "Wikipedia REST API")
            }
            Section("Credits") {
                Text("Eigenwort is a personal reader for Wikipedia, inspired by V for Wikipedia (Raureif, 2016) by Frank Rausch. Typographizer logic adapted from the Raureif/Typographizer project (MIT).")
                    .font(.callout)
                Text("Typography is set in EB Garamond by Georg Mayr-Duffner & Octavio Pardo. The De:Bug theme uses Besley by Owen Earl and Barlow Semi Condensed by Jeremy Tribby. All bundled fonts are under the SIL Open Font License.")
                    .font(.callout)
            }
            Section("Source") {
                Link("Wikipedia content is licensed under CC BY-SA 4.0.",
                     destination: URL(string: "https://creativecommons.org/licenses/by-sa/4.0/")!)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var appVersion: String {
        (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "1.0"
    }
}

// MARK: - Reusable toolbar modifier (unused now that the gear lives in the top header)

struct SettingsToolbarModifier: ViewModifier {
    @State private var showSettings = false

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .accessibilityLabel("Settings")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
    }
}

extension View {
    func withSettingsToolbar() -> some View {
        modifier(SettingsToolbarModifier())
    }
}
