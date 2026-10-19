import Foundation

/// Wikimedia's CDN rejects direct thumb requests outside its fixed ladder
/// (20/40/60/120/250/330/500/960/1280/1920/3840) with a 400, so every width
/// here must sit on it. See mediawiki.org/wiki/Common_thumbnail_sizes.
enum ThumbnailWidth {
    /// List rows and small avatars (44–64 pt).
    static let row = 250
    /// Today grid tiles (~half screen width).
    static let tile = 500
    /// Reader hero, full screen width.
    static let hero = 1280
    /// Lightbox: sharp at 3x and through a first zoom, and a bounded download
    /// per page when swiping through an article's pictures.
    static let lightbox = 1920
}

extension URL {
    /// The file a Wikimedia image URL shows, whichever rendering it is:
    /// `…/thumb/a/ab/Foo.jpg/640px-Foo.jpg` and `…/a/ab/Foo.jpg` are both
    /// `Foo.jpg`. How a tap on the page finds its picture in the media list.
    var wikimediaFileName: String {
        let parts = pathComponents
        if let thumb = parts.firstIndex(of: "thumb"), parts.count > thumb + 3 {
            return parts[thumb + 3]
        }
        return lastPathComponent
    }

    /// Rewrites the width segment of a Wikimedia thumbnail URL
    /// (`…/thumb/a/ab/Foo.jpg/320px-Foo.jpg` → `…/640px-Foo.jpg`). URLs without
    /// a `NNNpx-` filename prefix (originals, non-Wikimedia hosts) are returned
    /// unchanged — resizing only ever narrows an already-thumbnail URL, because
    /// constructing a thumb path from an original would need Wikimedia's
    /// per-format naming rules (`.svg.png`, `lossy-page1-….tif.jpg`, …).
    func wikimediaResized(to width: Int) -> URL {
        let string = absoluteString
        guard let slash = string.lastIndex(of: "/") else { return self }
        let filename = string[string.index(after: slash)...]
        guard let digits = filename.range(of: #"\d+(?=px-)"#, options: .regularExpression) else {
            return self
        }
        return URL(string: string.replacingCharacters(in: digits, with: String(width))) ?? self
    }
}

extension ArticleSummary {
    /// Right-sized display image: the summary's thumbnail re-requested at
    /// `width`, falling back to the original only when the original is already
    /// smaller than the request. Never fetches multi-MB originals for
    /// on-screen tiles or heroes — `ImageLightbox` is the one place the
    /// full-resolution file is legitimate.
    func imageURL(width: Int) -> URL? {
        if let originalWidth = originalImage?.width, originalWidth <= width {
            return originalImage?.source
        }
        return (thumbnail?.source ?? originalImage?.source)?.wikimediaResized(to: width)
    }
}
