import SwiftUI
import SwiftData

struct ArticleReaderView: View {
    @Environment(\.folioTheme) private var theme
    let title: String
    let language: String
    /// Where "Search for it" goes when Wikipedia has no article by this title.
    var onSearch: ((String) -> Void)?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(ReaderChrome.self) private var chrome: ReaderChrome?
    @Query private var bookmarks: [Bookmark]
    @Query private var settingsList: [AppSettings]

    @State private var summary: ArticleSummary?
    @State private var html: String?
    @State private var loadFailure: LoadFailure?
    @State private var historyRecorded = false

    @State private var sections: [ArticleSection] = []
    @State private var showTOC = false
    @State private var showGallery = false
    @State private var lookup: WordLookup?
    @State private var galleryItems: [MediaItem] = []
    @State private var lightbox: LightboxRequest?
    @State private var pendingScrollAnchor: String?
    @State private var alternateLink: LangLink?
    @State private var related: [SearchResult] = []
    @State private var pushedArticle: ArticleDestination?
    @State private var heroFocalPoint: CGPoint?
    @State private var cachedHeroURL: URL?
    @State private var visionComplete: Bool = false
    @State private var webViewReady: Bool = false
    @State private var reloadToken = UUID()
    @State private var initialScrollY: Double = 0
    @State private var toolbarReveal = ToolbarReveal()
    @State private var safeInsets = EdgeInsets()
    @State private var refreshTask: Task<Void, Never>?
    @State private var activeSectionAnchor: String?

    var body: some View {
        ZStack(alignment: .bottom) {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // The bar stays on a failure, as in V: sharing and bookmarking still
            // make sense, and contents and images grey out without an article.
            if html != nil || loadFailure != nil {
                BottomReaderToolbar(
                    isBookmarked: isBookmarked,
                    shareURL: shareURL,
                    themeIcon: themeIcon,
                    themeLabel: theme.displayName,
                    hasSections: !sections.isEmpty,
                    hasGallery: !galleryItems.isEmpty,
                    alternateLink: alternateLink,
                    fallbackLanguage: language,
                    onToggleBookmark: toggleBookmark,
                    onCycleTheme: cycleTheme,
                    onShowGallery: { showGallery = true },
                    onShowTOC: { showTOC = true }
                )
                .opacity(toolbarReveal.isVisible ? 1 : 0)
                .offset(y: toolbarReveal.isVisible ? 0 : 90)
                .allowsHitTesting(toolbarReveal.isVisible)
                .animation(.easeOut(duration: 0.22), value: toolbarReveal.isVisible)
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.28), value: contentPhase)
        .onGeometryChange(for: EdgeInsets.self) { $0.safeAreaInsets } action: { safeInsets = $0 }
        .overlay(alignment: .topLeading) {
            // Rises with the header, so it stays just under the clock.
            FloatingBackButton {
                dismiss()
            }
            .offset(y: chrome?.isHeaderHidden == true ? -(chrome?.headerHeight ?? 0) : 0)
            .animation(.easeOut(duration: 0.22), value: chrome?.isHeaderHidden)
        }
        .clearsHeader()
        // The app's header goes and comes back on the bar's rule.
        .onChange(of: toolbarReveal.isVisible) { _, isVisible in chrome?.isHeaderHidden = !isVisible }
        .onAppear { chrome?.isHeaderHidden = !toolbarReveal.isVisible }
        // Keep the nav bar present-but-invisible so UIKit's interactive pop
        // (swipe-from-leading-edge) still works. `.toolbar(.hidden)` removes the bar
        // entirely and disables the gesture.
        .toolbarBackground(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .task(id: identityKey) { await loadAll() }
        .sheet(isPresented: $showTOC) {
            TableOfContentsDrawer(
                articleTitle: displayTitle,
                thumbnailURL: summary?.thumbnailURL,
                sections: sections,
                activeAnchor: activeSectionAnchor,
                theme: theme
            ) { anchor in
                pendingScrollAnchor = anchor
            }
        }
        .sheet(isPresented: $showGallery) {
            ArticleImageGallery(items: galleryItems, theme: theme)
        }
        .sheet(item: $lookup) { lookup in
            WordLookupSheet(lookup: lookup, theme: theme)
        }
        .fullScreenCover(item: $lightbox) { request in
            ImageLightbox(request: request)
        }
        .navigationDestination(item: $pushedArticle) { dest in
            ArticleReaderView(title: dest.title, language: dest.language ?? language, onSearch: onSearch)
        }
        // Header EN/DE toggle changes AppSettings.defaultLanguage. When the user is
        // in an article and that global language differs from the current article's,
        // jump to the alternate-language version (if a langlink exists for it).
        .onChange(of: settings?.defaultLanguage) { oldLang, newLang in
            // `oldLang == nil` means the @Query just resolved from "no settings
            // row loaded yet" to "loaded" — that's not a user-driven toggle,
            // so don't auto-push. Otherwise an opening article whose language
            // differs from the persisted default would jump to the alt-lang
            // version immediately on first load.
            guard oldLang != nil else { return }
            guard let newLang, newLang != language else { return }
            if let alt = alternateLink, alt.lang == newLang {
                pushedArticle = ArticleDestination(title: alt.title, language: alt.lang)
            }
        }
        .onDisappear {
            refreshTask?.cancel()
            chrome?.isHeaderHidden = false
        }
        #if DEBUG
        // `-demoCycleThemes 1.6` steps through the looks as the theme button
        // would, once the page is up, for the film.
        // `-demoLookUp Treibgut` opens the dictionary sheet once the page is up.
        .onChange(of: webViewReady) { _, ready in
            guard ready, let word = UserDefaults.standard.string(forKey: "demoLookUp") else { return }
            lookup = WordLookup(word: word, language: language)
        }
        .onChange(of: webViewReady) { _, ready in
            let interval = UserDefaults.standard.double(forKey: "demoCycleThemes")
            guard ready, interval > 0 else { return }
            Task { @MainActor in
                for _ in 0..<4 {
                    try? await Task.sleep(for: .seconds(interval))
                    cycleTheme()
                }
            }
        }
        #endif
    }

    private enum ContentPhase: Int { case loading, preview, web }

    private var contentPhase: ContentPhase {
        if webViewReady { return .web }
        if summary != nil, visionComplete { return .preview }
        return .loading
    }

    @ViewBuilder
    private var content: some View {
        // Mount the WebView the moment HTML + focal are both available, but keep
        // it invisible until WKWebView's didFinish fires (`webViewReady`). The
        // ArticleLoadingPreview overlays on top until that happens, so the
        // cross-fade goes preview → painted-article without a blank gap.
        ZStack {
            if let html, visionComplete {
                ArticleWebView(
                    html: html,
                    articleURL: articleURL,
                    language: language,
                    currentTitle: title,
                    heroImageURL: cachedHeroURL ?? summary?.imageURL(width: ThumbnailWidth.hero),
                    heroFocalPoint: heroFocalPoint,
                    theme: theme,
                    fontScale: fontScale,
                    contentInsets: safeInsets,
                    initialScrollY: initialScrollY,
                    related: related,
                    relatedHeading: language == "de" ? "Ähnliche Artikel" : "Related",
                    pendingScrollAnchor: $pendingScrollAnchor,
                    onSections: { sections = $0 },
                    onImageTap: { lightbox = LightboxRequest(tapped: $0, caption: $1, in: galleryItems) },
                    onFontScale: persistFontScale,
                    onInternalLink: { pushedArticle = $0 },
                    onScroll: handleScroll,
                    onActiveSection: { activeSectionAnchor = $0 },
                    onReady: { webViewReady = true },
                    onReload: handleContentProcessTerminated,
                    onLookUp: { lookup = WordLookup(word: $0, language: language) }
                )
                .ignoresSafeArea()
                .opacity(webViewReady ? 1 : 0)
                // Critical: SwiftUI's .opacity(0) does NOT disable hit testing
                // for a UIKit view nested in a UIViewRepresentable. Without this,
                // WKWebView's scroll-view gesture recognizers grab the
                // leading-edge swipe before SwiftUI's interactive-pop ever sees
                // it — so on a dead/stuck WebView, swipe-back stops working.
                .allowsHitTesting(webViewReady)
                // Roll the identity to remount the WebView after a content
                // process crash. loadHTMLString-loaded views can't be reloaded
                // via WKWebView.reload(); rebuilding the view is the only path
                // that re-runs the render pipeline.
                .id(reloadToken)
            }

            if !webViewReady {
                if let loadFailure {
                    failurePage(loadFailure)
                        .transition(.opacity)
                } else if let summary, visionComplete {
                    ArticleLoadingPreview(
                        summary: summary,
                        theme: theme,
                        fontScale: fontScale,
                        heroFocalPoint: heroFocalPoint
                    )
                    .transition(.opacity)
                } else {
                    ProgressView()
                        .controlSize(.large)
                        .transition(.opacity)
                }
            }
        }
    }

    /// The title stays where the article would have started, as in V, so the
    /// page still says what failed to open.
    private func failurePage(_ failure: LoadFailure) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ArticleTitle(title: displayTitle, theme: theme, fontScale: fontScale)
            Spacer(minLength: 24)
            LoadFailureView(
                headline: "Couldn't load this article",
                failure: failure,
                retry: { Task { await loadAll() } },
                search: onSearch.map { search in { search(displayTitle) } }
            )
            .frame(maxWidth: .infinity)
            Spacer(minLength: 24)
            Spacer(minLength: 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(theme.paper)
    }

    private var identityKey: String { "\(language)/\(title)" }
    private var displayTitle: String { title.replacingOccurrences(of: "_", with: " ") }

    private var settings: AppSettings? { settingsList.first }
    /// Resolved once by ContentView, so Auto never reaches the stylesheet.
    private var fontScale: Double { settings?.fontScale ?? 1.0 }

    private var articleURL: URL {
        WikipediaEndpoint.articleURL(title: title, language: language)
            ?? URL(string: "https://wikipedia.org")!
    }

    /// The summary's URL is the canonical one, so a redirect such as "NYC"
    /// shares as the article it actually resolves to.
    private var shareURL: URL { summary?.pageURL ?? articleURL }

    private var isBookmarked: Bool {
        bookmarks.contains { $0.title == title && $0.language == language }
    }

    private var themeIcon: String { theme.iconName }

    private func cycleTheme() {
        guard let settings else { return }
        let cases = Theme.allCases
        let currentIndex = cases.firstIndex(where: { $0.rawValue == settings.theme }) ?? 0
        let next = cases[(currentIndex + 1) % cases.count]
        settings.theme = next.rawValue
        try? modelContext.save()
    }

    private func toggleBookmark() {
        if let existing = bookmarks.first(where: { $0.title == title && $0.language == language }) {
            modelContext.delete(existing)
        } else {
            modelContext.insert(
                Bookmark(
                    title: title,
                    language: language,
                    summary: summary?.description,
                    thumbnailURL: summary?.thumbnailURL
                )
            )
        }
        try? modelContext.save()
    }

    private func persistFontScale(_ scale: Double) {
        guard let settings, abs(settings.fontScale - scale) > 0.005 else { return }
        settings.fontScale = scale
        try? modelContext.save()
    }

    private func loadAll() async {
        // .task(id:) cancels on disappear and restarts on re-appear — even
        // when identityKey is unchanged (e.g. navigating to a sub-article
        // and swiping back). Without this guard, every back-swipe would
        // blow away visionComplete/webViewReady, unmount the WebView, and
        // strand the user on the preview waiting for didFinish on a freshly-
        // remounted pane. If we're already painted, do nothing.
        if webViewReady { return }

        loadFailure = nil
        alternateLink = nil
        related = []
        heroFocalPoint = nil
        cachedHeroURL = nil
        visionComplete = false
        webViewReady = false
        galleryItems = []
        initialScrollY = 0
        toolbarReveal = ToolbarReveal()
        #if DEBUG
        // Deterministic scroll for automated screenshots, e.g.
        // `-screenshotScrollY 1800`. Never set in a release build.
        initialScrollY = UserDefaults.standard.double(forKey: "screenshotScrollY")
        #endif
        // A refresh from a previous identity must not race the new render.
        refreshTask?.cancel()
        refreshTask = nil

        // Prefetched / previously-read articles carry hero URL + focal point
        // on the cache row, so the WebView mounts without a single network
        // round trip. Both are required — mounting hero-less and reloading
        // once the summary arrives would flash the whole document.
        if let cached = fetchCachedArticle(),
           let focal = cached.focalPoint, let hero = cached.heroImageURL {
            heroFocalPoint = focal
            cachedHeroURL = hero
            visionComplete = true
        }

        // Langlinks and the gallery only feed toolbar buttons (which handle
        // "not loaded yet" via disabled state) — they never gate first paint.
        async let htmlTask: () = loadHTML()
        async let langlinksTask: () = loadLanglinks()
        async let galleryTask: () = loadGallery()
        async let relatedTask: () = loadRelated()

        // Summary feeds the preview and share/bookmark metadata — and, when
        // the cache had no focal point, the hero image Vision runs on.
        await loadSummary()
        if !visionComplete {
            await resolveHeroFocalPoint()
            visionComplete = true
        }

        _ = await htmlTask
        // The cache row exists once loadHTML finished — write back whatever
        // it's missing so the next open takes the no-network fast path.
        if let focal = heroFocalPoint { persistFocalPoint(focal) }
        recordHistoryIfNeeded()
        _ = await (langlinksTask, galleryTask, relatedTask)
    }

    /// Resolves the hero focal point via cache → Vision → persist. Cached articles
    /// return instantly; new articles run face detection once and write the result
    /// back to CachedArticle so the next open is flash-free without any network.
    private func resolveHeroFocalPoint() async {
        if let cached = fetchCachedArticle(), let focal = cached.focalPoint {
            heroFocalPoint = focal
            return
        }

        guard let summary,
              let focal = await FocalPointDetector.shared.resolvedFocalPoint(for: summary)
        else { return }
        heroFocalPoint = focal
        persistFocalPoint(focal)
    }

    private func persistFocalPoint(_ focal: CGPoint) {
        guard let entry = fetchCachedArticle() else { return }
        entry.focalPointX = focal.x
        entry.focalPointY = focal.y
        if entry.heroImageURL == nil {
            entry.heroImageURL = summary?.imageURL(width: ThumbnailWidth.hero)
        }
        try? modelContext.save()
    }

    private func loadGallery() async {
        galleryItems = (try? await WikipediaClient.shared.mediaList(title: title, language: language)) ?? []
    }

    private func handleScroll(_ scroll: ReaderScroll) {
        toolbarReveal.update(y: scroll.y, remaining: scroll.remaining)
    }

    /// Called when WKWebView's content process is terminated by iOS. Dropping
    /// webViewReady re-overlays the preview; rolling reloadToken changes the
    /// WebView's SwiftUI identity, so the next render dismantles the dead pane
    /// and constructs a fresh one — which fires loadHTMLString cleanly.
    private func handleContentProcessTerminated() {
        webViewReady = false
        reloadToken = UUID()
    }

    private func loadRelated() async {
        related = (try? await WikipediaClient.shared.related(title: title, language: language)) ?? []
    }

    private func loadLanglinks() async {
        let links = (try? await WikipediaClient.shared.langlinks(title: title, language: language)) ?? []
        alternateLink = links.first { $0.lang == alternateLanguage }
    }

    private var alternateLanguage: String {
        language == "de" ? "en" : "de"
    }

    private func loadSummary() async {
        summary = try? await WikipediaClient.shared.summary(title: title, language: language)
    }

    private func loadHTML() async {
        // Cache first — instant render if we have anything stored. Stale entries still
        // render immediately, then we silently refresh in the background.
        if let cached = fetchCachedArticle() {
            html = cached.html
            if !cached.isFresh {
                scheduleRefresh()
            }
            return
        }
        await fetchAndCacheHTML()
    }

    private func fetchAndCacheHTML() async {
        do {
            let fresh = try await WikipediaClient.shared.mobileHTML(title: title, language: language)
            html = fresh
            upsertCache(html: fresh)
        } catch {
            if Task.isCancelled { return }
            loadFailure = LoadFailure(error)
        }
    }

    /// Tracked, cancellable background refresh — previously a detached
    /// `Task { @MainActor in ... }` that outlived view identity and could
    /// still write into a stale view's `html` after the user had navigated
    /// away and back. Now owned by view state and cancelled on disappear /
    /// at the start of every fresh `loadAll`.
    private func scheduleRefresh() {
        refreshTask?.cancel()
        refreshTask = Task { @MainActor in
            do {
                let fresh = try await WikipediaClient.shared.mobileHTML(title: title, language: language)
                if Task.isCancelled { return }
                html = fresh
                upsertCache(html: fresh)
            } catch {
                // Silent — stale cache stays in place.
            }
        }
    }

    private func fetchCachedArticle() -> CachedArticle? {
        CachedArticle.fetch(title: title, language: language, in: modelContext)
    }

    private func upsertCache(html: String) {
        CachedArticle.upsert(
            title: title,
            language: language,
            html: html,
            focalPoint: heroFocalPoint,
            heroImageURL: summary?.imageURL(width: ThumbnailWidth.hero),
            in: modelContext
        )
    }

    private func recordHistoryIfNeeded() {
        guard !historyRecorded else { return }
        historyRecorded = true

        // History lists articles, not visits: re-reading one bumps its existing
        // row to the top instead of stacking another copy.
        let snapshotTitle = title
        let snapshotLanguage = language
        let descriptor = FetchDescriptor<HistoryEntry>(
            predicate: #Predicate { entry in
                entry.title == snapshotTitle && entry.language == snapshotLanguage
            },
            sortBy: [SortDescriptor(\.readAt, order: .reverse)]
        )
        let existing = (try? modelContext.fetch(descriptor)) ?? []
        if let newest = existing.first {
            newest.readAt = .now
            // Backfill thumb/summary if the row was missing it.
            if newest.thumbnailURL == nil, let url = summary?.thumbnailURL {
                newest.thumbnailURL = url
            }
            if newest.summary == nil, let desc = summary?.description {
                newest.summary = desc
            }
            for stale in existing.dropFirst() { modelContext.delete(stale) }
            try? modelContext.save()
            return
        }

        // Backfill from any prior record when the live summary came back
        // without metadata (typical on flaky cellular) — otherwise the same
        // article shows up with a thumbnail one day and without it the next.
        let fallback = previousMetadata()
        modelContext.insert(
            HistoryEntry(
                title: title,
                language: language,
                summary: summary?.description ?? fallback.summary,
                thumbnailURL: summary?.thumbnailURL ?? fallback.thumbnailURL
            )
        )
        try? modelContext.save()
    }

    /// Find the most recent thumbnail / description we've previously stored
    /// for this (title, language). Checks history first (more frequently
    /// updated) then bookmarks.
    private func previousMetadata() -> (summary: String?, thumbnailURL: URL?) {
        let snapshotTitle = title
        let snapshotLanguage = language
        let historyDescriptor = FetchDescriptor<HistoryEntry>(
            predicate: #Predicate { entry in
                entry.title == snapshotTitle && entry.language == snapshotLanguage
            },
            sortBy: [SortDescriptor(\.readAt, order: .reverse)]
        )
        if let entry = try? modelContext.fetch(historyDescriptor).first(where: { $0.thumbnailURL != nil || $0.summary != nil }) {
            return (entry.summary, entry.thumbnailURL)
        }
        let bookmarkDescriptor = FetchDescriptor<Bookmark>(
            predicate: #Predicate { entry in
                entry.title == snapshotTitle && entry.language == snapshotLanguage
            }
        )
        if let entry = try? modelContext.fetch(bookmarkDescriptor).first {
            return (entry.summary, entry.thumbnailURL)
        }
        return (nil, nil)
    }
}

private struct FloatingBackButton: View {
    @Environment(\.folioTheme) private var theme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(width: 40, height: 40)
                .background(theme.barBackground, in: Circle())
                .shadow(color: .black.opacity(0.18), radius: 6, y: 2)
        }
        .accessibilityLabel("Back")
        .padding(.leading, 14)
        .padding(.top, 8)
    }
}

private struct BottomReaderToolbar: View {
    @Environment(\.folioTheme) private var theme
    let isBookmarked: Bool
    let shareURL: URL
    let themeIcon: String
    let themeLabel: String
    let hasSections: Bool
    let hasGallery: Bool
    let alternateLink: LangLink?
    let fallbackLanguage: String
    let onToggleBookmark: () -> Void
    let onCycleTheme: () -> Void
    let onShowGallery: () -> Void
    let onShowTOC: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            ShareLink(item: shareURL) {
                Image(systemName: "square.and.arrow.up")
                    .accessibilityLabel("Share")
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())

            if let alt = alternateLink {
                NavigationLink(value: ArticleDestination(title: alt.title, language: alt.lang)) {
                    Image(systemName: "character.bubble")
                        .accessibilityLabel("Read in \(displayLanguage(alt.lang))")
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
            }

            Button(action: onToggleBookmark) {
                Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                    .accessibilityLabel(isBookmarked ? "Remove bookmark" : "Add bookmark")
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())

            Button(action: onCycleTheme) {
                Image(systemName: themeIcon)
                    .accessibilityLabel("Theme: \(themeLabel)")
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())

            Button(action: onShowGallery) {
                Image(systemName: "square.grid.2x2")
                    .accessibilityLabel("Images")
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .disabled(!hasGallery)
            .opacity(hasGallery ? 1.0 : 0.4)

            Button(action: onShowTOC) {
                Image(systemName: "list.bullet")
                    .accessibilityLabel("Contents")
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .disabled(!hasSections)
            .opacity(hasSections ? 1.0 : 0.4)
        }
        .font(.system(size: 19, weight: .regular))
        .foregroundStyle(Color.primary)
        .buttonStyle(.plain)
        .frame(height: 44)
        .background(theme.barBackground)
        .clipShape(Capsule())
        .overlay(
            Capsule().stroke(theme.palette.hairlineColor, lineWidth: theme.palette.hasRim ? 1.5 : 0.75)
        )
        .padding(.horizontal, 28)
        .padding(.bottom, 12)
    }

    private func displayLanguage(_ code: String) -> String {
        switch code {
        case "en": "English"
        case "de": "Deutsch"
        default: code.uppercased()
        }
    }
}
