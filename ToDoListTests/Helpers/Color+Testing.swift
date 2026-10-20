import SwiftUI
import UIKit

extension Color {
    /// Resolves to an `RRGGBB` (or `RRGGBBAA` when translucent) hex string under the light appearance.
    var lightHex: String {
        let resolved = UIColor(self).resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
        var (r, g, b, a): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
        resolved.getRed(&r, green: &g, blue: &b, alpha: &a)
        func byte(_ v: CGFloat) -> Int { Int((v * 255).rounded()) }
        let rgb = String(format: "%02X%02X%02X", byte(r), byte(g), byte(b))
        return a < 1 ? rgb + String(format: "%02X", byte(a)) : rgb
    }
}
