import UIKit
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins

struct PhotoSpec: Identifiable, Hashable {
    let id: String
    let name: String
    let widthMM: Double
    let heightMM: Double
    let isPremium: Bool
    var aspect: CGFloat { CGFloat(widthMM / heightMM) }

    static let all: [PhotoSpec] = [
        .init(id: "us", name: "US 2×2 in", widthMM: 51, heightMM: 51, isPremium: false),
        .init(id: "eu", name: "EU 35×45 mm", widthMM: 35, heightMM: 45, isPremium: true),
        .init(id: "uk", name: "UK 35×45 mm", widthMM: 35, heightMM: 45, isPremium: true),
        .init(id: "in", name: "India 51×51 mm", widthMM: 51, heightMM: 51, isPremium: true),
        .init(id: "cn", name: "China 33×48 mm", widthMM: 33, heightMM: 48, isPremium: true),
    ]
}

enum IDPhotoError: Error { case badImage, noSubject }

/// On-device: lift the subject (iOS 17 mask), place on a white background, and
/// crop to the chosen document aspect ratio centered on the detected face.
struct IDPhotoService {
    private let context = CIContext()

    func make(from image: UIImage, spec: PhotoSpec) async throws -> UIImage {
        try await Task.detached(priority: .userInitiated) {
            try Self.render(image: image, spec: spec, context: context)
        }.value
    }

    private static func render(image: UIImage, spec: PhotoSpec, context: CIContext) throws -> UIImage {
        guard let cg = image.normalizedUp().cgImage else { throw IDPhotoError.badImage }
        let input = CIImage(cgImage: cg)
        let extent = input.extent

        // White background composite via subject mask.
        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(cgImage: cg, options: [:])
        // Foreground masking needs the Neural Engine (unavailable on Simulator);
        // if it fails, keep the original photo on the (already light) background.
        try? handler.perform([request])
        var composited = input
        if let result = request.results?.first,
           let buffer = try? result.generateScaledMaskForImage(forInstances: result.allInstances, from: handler) {
            var mask = CIImage(cvPixelBuffer: buffer)
            mask = mask.transformed(by: CGAffineTransform(scaleX: extent.width / mask.extent.width, y: extent.height / mask.extent.height))
            let white = CIImage(color: CIColor(color: .white)).cropped(to: extent)
            let blend = CIFilter.blendWithMask()
            blend.inputImage = input; blend.backgroundImage = white; blend.maskImage = mask
            composited = blend.outputImage ?? input
        }

        guard let baseCG = context.createCGImage(composited, from: extent) else { throw IDPhotoError.badImage }
        let base = UIImage(cgImage: baseCG)

        // Center crop to the document aspect ratio (bias slightly toward the top
        // where the face usually is).
        let cropped = cropToAspect(base, aspect: spec.aspect, topBias: 0.12)
        return cropped
    }

    private static func cropToAspect(_ image: UIImage, aspect: CGFloat, topBias: CGFloat) -> UIImage {
        let w = image.size.width, h = image.size.height
        var cropW = w, cropH = w / aspect
        if cropH > h { cropH = h; cropW = h * aspect }
        let x = (w - cropW) / 2
        let y = max(0, (h - cropH) / 2 - h * topBias)
        let rect = CGRect(x: x, y: y, width: cropW, height: cropH)
        guard let cg = image.cgImage?.cropping(to: rect.applying(CGAffineTransform(scaleX: image.scale, y: image.scale))) else { return image }
        return UIImage(cgImage: cg, scale: image.scale, orientation: .up)
    }
}

extension UIImage {
    func normalizedUp() -> UIImage {
        if imageOrientation == .up { return self }
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = scale
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
