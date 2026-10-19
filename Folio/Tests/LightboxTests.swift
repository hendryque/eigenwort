import CoreGraphics
import Foundation
import Testing
@testable import Folio

/// The lightbox's swipe used to be swallowed by its own pan gesture, and a tap
/// opened one picture with nothing either side. These pin what a drag means
/// and how a tap on the page finds its place among the article's pictures.
struct LightboxTests {

    private let width: CGFloat = 402

    private func drag(_ moves: CGSize...) -> LightboxDrag {
        var drag = LightboxDrag()
        moves.forEach { drag.update($0) }
        return drag
    }

    @Test("A tap's jitter decides nothing")
    func smallMovesLeaveTheAxisOpen() {
        #expect(drag(CGSize(width: 4, height: 6)).axis == nil)
    }

    @Test("The first clear direction wins and stays")
    func axisLocks() {
        let sideways = drag(CGSize(width: 14, height: 3), CGSize(width: 14, height: 90))
        #expect(sideways.axis == .horizontal)
        let downward = drag(CGSize(width: 2, height: 15), CGSize(width: 160, height: 20))
        #expect(downward.axis == .vertical)
    }

    @Test("Sideways turns the page once it would end past half the width")
    func paging() {
        let left = drag(CGSize(width: -30, height: 0))
        #expect(left.outcome(translation: CGSize(width: -60, height: 0), predicted: CGSize(width: -260, height: 0), width: width) == .page(1))
        let right = drag(CGSize(width: 30, height: 0))
        #expect(right.outcome(translation: CGSize(width: 220, height: 0), predicted: CGSize(width: 240, height: 0), width: width) == .page(-1))
        #expect(left.outcome(translation: CGSize(width: -60, height: 0), predicted: CGSize(width: -90, height: 0), width: width) == .stay)
    }

    @Test("Vertically, a short drag springs back and a long one or a flick closes")
    func dismissing() {
        let down = drag(CGSize(width: 0, height: 20))
        #expect(down.outcome(translation: CGSize(width: 0, height: 60), predicted: CGSize(width: 0, height: 90), width: width) == .stay)
        #expect(down.outcome(translation: CGSize(width: 0, height: 130), predicted: CGSize(width: 0, height: 140), width: width) == .dismiss)
        #expect(down.outcome(translation: CGSize(width: 0, height: 40), predicted: CGSize(width: 0, height: 400), width: width) == .dismiss)
        #expect(down.outcome(translation: CGSize(width: 0, height: -130), predicted: CGSize(width: 0, height: -140), width: width) == .dismiss)
    }

    @Test("Every rendering of a Wikimedia file names the same file")
    func fileNames() {
        let thumb = URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/6/6d/Nathan_Fielder.jpg/640px-Nathan_Fielder.jpg")!
        let original = URL(string: "https://upload.wikimedia.org/wikipedia/commons/6/6d/Nathan_Fielder.jpg")!
        let otherHost = URL(string: "https://thumb.wikimedia.org/wikipedia/en/thumb/9/9d/Poster.jpeg/250px-Poster.jpeg")!
        #expect(thumb.wikimediaFileName == "Nathan_Fielder.jpg")
        #expect(original.wikimediaFileName == "Nathan_Fielder.jpg")
        #expect(otherHost.wikimediaFileName == "Poster.jpeg")
    }

    private func item(_ name: String, caption: String? = nil) -> MediaItem {
        MediaItem(
            id: "File:\(name)",
            thumbnailURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/a/ab/\(name)/320px-\(name)")!,
            originalURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/a/ab/\(name)/640px-\(name)")!,
            caption: caption
        )
    }

    @Test("A tapped picture opens among the article's, at its own place")
    func tapFindsItsPlace() {
        let items = [item("Poster.jpg"), item("Fielder.jpg", caption: "Nathan Fielder"), item("Oppenheim.jpg")]
        let tapped = URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/a/ab/Oppenheim.jpg/220px-Oppenheim.jpg")!
        let request = LightboxRequest(tapped: tapped, caption: "Lance Oppenheim (right)", in: items)
        #expect(request.images.count == 3)
        #expect(request.start == 2)
        // The list had no caption for it, so the page's is kept.
        #expect(request.images[2].caption == "Lance Oppenheim (right)")
        #expect(request.images[1].caption == "Nathan Fielder")
    }

    @Test("A picture the list lacks opens alone")
    func unlistedOpensAlone() {
        let icon = URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/c/cf/Flag.svg/40px-Flag.svg.png")!
        let request = LightboxRequest(tapped: icon, caption: nil, in: [item("Poster.jpg")])
        #expect(request.images.count == 1)
        #expect(request.images[0].url == icon)
    }

    @Test("The lightbox asks Wikimedia for a rendering on its width ladder")
    func largeRenderingIsOnTheLadder() {
        let image = LightboxImage(item("Fielder.jpg"))
        #expect(image.largeURL.lastPathComponent == "\(ThumbnailWidth.lightbox)px-Fielder.jpg")
    }
}
