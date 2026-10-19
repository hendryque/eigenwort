import SwiftUI

/// One picture the lightbox can show. `id` is its file name, which is how a
/// tap on the page finds its place in the article's media list.
struct LightboxImage: Hashable {
    let id: String
    let url: URL
    let caption: String?

    /// Wikimedia's larger rendering. An original comes back unchanged, and a
    /// small original cannot be scaled up, so the page falls back to `url`.
    var largeURL: URL { url.wikimediaResized(to: ThumbnailWidth.lightbox) }
}

extension LightboxImage {
    init(_ item: MediaItem) {
        self.init(id: item.originalURL.wikimediaFileName, url: item.originalURL, caption: item.caption)
    }
}

/// What the lightbox opens with: the pictures to page through and the first.
struct LightboxRequest: Identifiable {
    let images: [LightboxImage]
    let start: Int
    var id: String { images[start].id }
}

extension LightboxRequest {
    /// A tap on the page opens among the article's pictures, in page order. One
    /// the list lacks, a small icon or a list still loading, opens alone.
    init(tapped url: URL, caption: String?, in items: [MediaItem]) {
        var images = items.map(LightboxImage.init)
        guard let start = images.firstIndex(where: { $0.id == url.wikimediaFileName }) else {
            self.init(images: [LightboxImage(id: url.wikimediaFileName, url: url, caption: caption)], start: 0)
            return
        }
        if images[start].caption == nil {
            images[start] = LightboxImage(id: images[start].id, url: images[start].url, caption: caption)
        }
        self.init(images: images, start: start)
    }

    /// The gallery opens at the picture chosen.
    init(items: [MediaItem], start item: MediaItem) {
        self.init(images: items.map(LightboxImage.init), start: items.firstIndex(of: item) ?? 0)
    }
}

/// Full screen pictures: swipe sideways through the article's, drag down or
/// up to close, pinch or double-tap to zoom, tap for the picture alone.
struct ImageLightbox: View {
    private let images: [LightboxImage]

    @Environment(\.dismiss) private var dismiss
    @State private var index: Int
    @State private var drag = LightboxDrag()
    @State private var translation: CGSize = .zero
    @State private var isZoomed = false
    @State private var isPinching = false
    @State private var pinchInterrupted = false
    @State private var showsChrome = true

    init(request: LightboxRequest) {
        images = request.images
        _index = State(initialValue: request.start)
    }

    var body: some View {
        ZStack {
            GeometryReader { geometry in
                ZStack {
                    Color.black.opacity(backdropOpacity)
                    ForEach(neighbours, id: \.self) { page in
                        LightboxPage(
                            image: images[page],
                            isZoomed: page == index ? $isZoomed : .constant(false),
                            isPinching: $isPinching,
                            onTap: { withAnimation(.easeOut(duration: 0.2)) { showsChrome.toggle() } }
                        )
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .offset(
                            x: CGFloat(page - index) * geometry.size.width + pageOffset,
                            y: page == index ? verticalOffset : 0
                        )
                    }
                }
                .contentShape(Rectangle())
                .gesture(pager(width: geometry.size.width), including: isZoomed ? .subviews : .all)
                .accessibilityElement()
                .accessibilityLabel(images[index].caption ?? "Picture")
                .accessibilityValue(images.count > 1 ? "\(index + 1) of \(images.count)" : "")
                .accessibilityAdjustableAction { direction in
                    switch direction {
                    case .increment: go(to: index + 1)
                    case .decrement: go(to: index - 1)
                    @unknown default: break
                    }
                }
            }
            .ignoresSafeArea()

            if chromeVisible {
                VStack(spacing: 0) {
                    topBar
                    Spacer(minLength: 0)
                    if let caption = images[index].caption, !caption.isEmpty {
                        Text(caption)
                            .font(.custom("EBGaramond-Regular", size: 15, relativeTo: .footnote))
                            .foregroundStyle(.white.opacity(0.85))
                            .multilineTextAlignment(.center)
                            .lineLimit(4)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 20)
                            .allowsHitTesting(false)
                    }
                }
                .transition(.opacity)
            }
        }
        .statusBarHidden(!showsChrome)
        // White clock over the black, whatever the reader's theme.
        .preferredColorScheme(.dark)
        // Lets the article show through as the black fades on a drag down.
        .presentationBackground(.clear)
    }

    private var topBar: some View {
        ZStack {
            if images.count > 1 {
                Text("\(index + 1) / \(images.count)")
                    .font(.footnote.weight(.medium).monospacedDigit())
                    .foregroundStyle(.white.opacity(0.85))
                    .allowsHitTesting(false)
            }
            HStack {
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .foregroundStyle(.white)
                        .background(Color.black.opacity(0.4), in: Circle())
                }
                .accessibilityLabel("Close")
            }
        }
        .padding(16)
    }

    private var neighbours: [Int] { Array(max(0, index - 1)...min(images.count - 1, index + 1)) }

    /// Past either end the page gives a third of the drag, so it feels held.
    private var pageOffset: CGFloat {
        guard drag.axis == .horizontal else { return 0 }
        let pastEnd = (translation.width > 0 && index == 0) || (translation.width < 0 && index == images.count - 1)
        return pastEnd ? translation.width / 3 : translation.width
    }

    private var verticalOffset: CGFloat { drag.axis == .vertical ? translation.height : 0 }
    private var backdropOpacity: Double { 1 - min(0.8, abs(verticalOffset) / 500) }
    private var chromeVisible: Bool { showsChrome && drag.axis != .vertical }

    private func pager(width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                // A second finger turns the drag into a pinch; it must not page.
                if isPinching {
                    pinchInterrupted = true
                    translation = .zero
                    return
                }
                drag.update(value.translation)
                translation = value.translation
            }
            .onEnded { value in
                let outcome = pinchInterrupted ? .stay : drag.outcome(
                    translation: value.translation,
                    predicted: value.predictedEndTranslation,
                    width: width
                )
                pinchInterrupted = false
                if outcome == .dismiss {
                    dismiss()
                    return
                }
                withAnimation(.spring(duration: 0.32)) {
                    if case .page(let step) = outcome { go(to: index + step) }
                    translation = .zero
                    drag = LightboxDrag()
                }
            }
    }

    private func go(to page: Int) {
        guard images.indices.contains(page) else { return }
        index = page
        isZoomed = false
    }
}

/// One picture, fitted to the screen. Pinch or double-tap to zoom, drag to pan
/// while zoomed. Wikimedia's larger rendering first, the page's size after.
private struct LightboxPage: View {
    let image: LightboxImage
    @Binding var isZoomed: Bool
    @Binding var isPinching: Bool
    let onTap: () -> Void

    @State private var scale: CGFloat = 1
    @State private var baseScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var baseOffset: CGSize = .zero
    @State private var usesPageSize = false

    private static let maxScale: CGFloat = 5
    private static let doubleTapScale: CGFloat = 2.5

    var body: some View {
        GeometryReader { geometry in
            // Full-res decodes are capped: a 100-megapixel Commons scan would
            // otherwise decompress to ~400MB and kill the app.
            RemoteImage(url: usesPageSize ? image.url : image.largeURL, maxPixelSize: 4096) { phase in
                switch phase {
                case .success(let picture):
                    picture
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(scale)
                        .offset(offset)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .contentShape(Rectangle())
                        .onTapGesture(count: 2) { location in toggleZoom(at: location, in: geometry.size) }
                        .onTapGesture(perform: onTap)
                        .highPriorityGesture(magnify(in: geometry.size))
                        .gesture(pan(in: geometry.size), including: scale > 1 ? .all : .subviews)
                case .failure where !usesPageSize:
                    Color.clear.onAppear { usesPageSize = true }
                case .failure:
                    VStack(spacing: 12) {
                        Image(systemName: "photo")
                            .font(.largeTitle)
                        Text("Couldn't load image")
                    }
                    .foregroundStyle(.white.opacity(0.6))
                    .frame(width: geometry.size.width, height: geometry.size.height)
                default:
                    ProgressView()
                        .tint(.white)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                }
            }
        }
        .onChange(of: scale) { _, scale in isZoomed = scale > 1.01 }
    }

    private func toggleZoom(at point: CGPoint, in size: CGSize) {
        withAnimation(.spring(duration: 0.3)) {
            if scale > 1.01 {
                scale = 1
                offset = .zero
            } else {
                // Bring the tapped spot to the middle, as far as the edges allow.
                scale = Self.doubleTapScale
                let toMiddle = CGSize(width: (size.width / 2 - point.x) * scale, height: (size.height / 2 - point.y) * scale)
                offset = clamped(toMiddle, scale: scale, in: size)
            }
        }
        baseScale = scale
        baseOffset = offset
    }

    private func magnify(in size: CGSize) -> some Gesture {
        MagnifyGesture()
            .onChanged { value in
                isPinching = true
                let next = min(Self.maxScale, max(1, baseScale * value.magnification))
                scale = next
                offset = clamped(baseOffset, scale: next, in: size)
            }
            .onEnded { _ in
                isPinching = false
                withAnimation(.spring(duration: 0.3)) {
                    if scale < 1.05 {
                        scale = 1
                        offset = .zero
                    }
                }
                baseScale = scale
                baseOffset = offset
            }
    }

    private func pan(in size: CGSize) -> some Gesture {
        DragGesture()
            .onChanged { value in
                let moved = CGSize(
                    width: baseOffset.width + value.translation.width,
                    height: baseOffset.height + value.translation.height
                )
                offset = clamped(moved, scale: scale, in: size)
            }
            .onEnded { _ in baseOffset = offset }
    }

    private func clamped(_ offset: CGSize, scale: CGFloat, in size: CGSize) -> CGSize {
        let x = (scale - 1) * size.width / 2
        let y = (scale - 1) * size.height / 2
        return CGSize(width: min(x, max(-x, offset.width)), height: min(y, max(-y, offset.height)))
    }
}
