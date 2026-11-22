import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit

/// Gimmick's pop art: a picture as real halftone in two of the costume's
/// colours, dots that grow with the tone on a screen turned 45°, as comics
/// were printed. Made once per picture and pair; scrolling draws the result.
enum Halftone {
    /// In points: fine enough, with the lighter tone, that faces stay faces.
    static let pitch: CGFloat = 4.5

    private static let context = CIContext()
    private static let made = DecodedImageCache(totalCostLimit: 32 * 1024 * 1024)

    static func cached(_ key: String) -> UIImage? { made[key] }

    /// The picture at `url` screened to fill `size` points, or, without a
    /// picture, the screen over a flat tone.
    static func picture(at url: URL?, fill size: CGSize, scale: CGFloat, light: UIColor, dark: UIColor, key: String) async -> UIImage? {
        if let hit = made[key] { return hit }
        var source: UIImage?
        if let url {
            source = await ImageLoader.shared.image(for: url)
            guard source != nil else { return nil }
        }
        let image = await Task.detached(priority: .userInitiated) { [source] in
            render(source, fill: size, scale: scale, light: light, dark: dark)
        }.value
        if let image { made.set(image, forKey: key) }
        return image
    }

    static func render(_ source: UIImage?, fill size: CGSize, scale: CGFloat, light: UIColor, dark: UIColor) -> UIImage? {
        let input: CIImage
        if let picture = source?.cgImage {
            input = CIImage(cgImage: picture)
        } else {
            input = CIImage(color: CIColor(red: 0.8, green: 0.8, blue: 0.8))
                .cropped(to: CGRect(x: 0, y: 0, width: size.width * scale, height: size.height * scale))
        }
        let extent = input.extent
        guard extent.width > 0, extent.height > 0 else { return nil }
        // The picture fills the tile, so a pixel spans this many points.
        let points = max(size.width / extent.width, size.height / extent.height)

        // Lifted before screening: at full darkness faces drowned in the ink.
        let tone = CIFilter.colorControls()
        tone.inputImage = input
        tone.saturation = 0
        tone.contrast = 1.05
        tone.brightness = source == nil ? 0 : 0.15
        let dots = CIFilter.dotScreen()
        dots.inputImage = tone.outputImage
        dots.center = .zero
        dots.angle = .pi / 4
        dots.width = Float(pitch / points)
        dots.sharpness = 0.7
        let ink = CIFilter.falseColor()
        ink.inputImage = dots.outputImage
        ink.color0 = CIColor(color: dark)
        ink.color1 = CIColor(color: light)
        guard let output = ink.outputImage?.cropped(to: extent),
              let made = context.createCGImage(output, from: extent) else { return nil }
        return UIImage(cgImage: made)
    }
}
