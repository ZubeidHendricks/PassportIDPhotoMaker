import XCTest
import UIKit
// IDPhotoService.swift compiled into this test target.

final class IDPhotoTests: XCTestCase {
    private func image(_ w: CGFloat, _ h: CGFloat) -> UIImage {
        let f = UIGraphicsImageRendererFormat.default(); f.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: w, height: h), format: f).image { c in
            UIColor.lightGray.setFill(); c.fill(CGRect(x: 0, y: 0, width: w, height: h))
        }
    }

    func testSpecCatalog() {
        XCTAssertGreaterThanOrEqual(PhotoSpec.all.count, 3)
        XCTAssertFalse(PhotoSpec.all[0].isPremium)
    }

    func testOutputMatchesSpecAspectRatio() async throws {
        let spec = PhotoSpec.all.first { $0.id == "us" }!     // 51x51 -> aspect 1
        let out = try await IDPhotoService().make(from: image(400, 600), spec: spec)
        let w = Double(out.cgImage!.width), h = Double(out.cgImage!.height)
        XCTAssertEqual(w / h, Double(spec.aspect), accuracy: 0.05)
    }
}
