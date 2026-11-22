import Testing
import UIKit
@testable import Folio

/// Gimmick's Today: pictures as real halftone in pairs of its own colours.
struct HalftoneTests {

    /// Share of pixels close to `color`, read back from the rendered image.
    private func share(of color: UIColor, in image: UIImage) -> Double {
        guard let cg = image.cgImage else { return 0 }
        let width = cg.width, height = cg.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let space = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(data: &pixels, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
                                      space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return 0 }
        context.draw(cg, in: CGRect(x: 0, y: 0, width: width, height: height))
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        var close = 0
        for i in stride(from: 0, to: pixels.count, by: 4) {
            let distance = abs(Double(pixels[i]) - r * 255) + abs(Double(pixels[i + 1]) - g * 255) + abs(Double(pixels[i + 2]) - b * 255)
            if distance < 60 { close += 1 }
        }
        return Double(close) / Double(width * height)
    }

    @Test("A tile without a picture gets the screen over a flat tone, dots on ground")
    func flatTile() throws {
        let image = try #require(Halftone.render(nil, fill: CGSize(width: 100, height: 133), scale: 2, light: .yellow, dark: .blue))
        #expect(image.cgImage?.width == 200)
        #expect(share(of: .yellow, in: image) > 0.3)
        #expect(share(of: .blue, in: image) > 0.05)
    }

    @Test("A picture keeps its pixels and comes back in the pair's two colours")
    func picture() throws {
        let source = UIGraphicsImageRenderer(size: CGSize(width: 120, height: 160)).image { context in
            UIColor.black.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 120, height: 80))
            UIColor.white.setFill()
            context.fill(CGRect(x: 0, y: 80, width: 120, height: 80))
        }
        let image = try #require(Halftone.render(source, fill: CGSize(width: 120, height: 160), scale: 1, light: .yellow, dark: .red))
        #expect(image.cgImage?.width == source.cgImage?.width)
        #expect(share(of: .yellow, in: image) + share(of: .red, in: image) > 0.8)
    }

    @Test("The pop art's pairs are Gimmick's own colours")
    func pairsFromPalette() {
        let palette = Theme.gimmick.palette
        var own: Set<UInt32> = [palette.card, palette.accent, palette.link, palette.background]
        if let band = palette.band { own.formUnion([band.0, band.1]) }
        for pair in PopArtPair.pairs(in: palette) {
            #expect(own.contains(pair.light))
            #expect(own.contains(pair.dark))
        }
    }
}
