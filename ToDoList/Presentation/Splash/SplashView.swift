import SwiftUI

/// Branded screen shown until the first load finishes. Decorative art is hidden from VoiceOver;
/// the screen as a whole reads as "Loading tasks".
struct SplashView: View {
    let layout: SplashLayout

    init(layout: SplashLayout = .design) {
        self.layout = layout
    }

    var body: some View {
        VStack(spacing: 36) {
            disc
            Text("one thing at a time")
                .font(DSFont.tagline.font)
                .foregroundStyle(DSColor.splashSoft)
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, 40)
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background { DSGradient.splash.linearGradient.ignoresSafeArea() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Loading tasks")
    }

    private var disc: some View {
        Circle().fill(DSColor.splashCream)
            .frame(width: layout.disc, height: layout.disc)
            .dsShadow(.splash)
            .overlay {
                Image(systemName: "checkmark")
                    .font(.system(size: layout.checkSize, weight: .semibold))
                    .foregroundStyle(DSColor.accent)
            }
            .background { art }
    }

    /// Drawn behind the disc and centered on it, so every offset in the layout is relative to the disc center.
    private var art: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(
                    colors: [DSColor.splashGlow, DSColor.splashGlow.opacity(0)],
                    center: .center, startRadius: 0, endRadius: layout.glow.diameter / 2
                ))
                .frame(width: layout.glow.diameter, height: layout.glow.diameter)
                .offset(layout.glow.offset)
            Circle()
                .strokeBorder(DSColor.splashRing, lineWidth: layout.ringLineWidth)
                .frame(width: layout.ring.diameter, height: layout.ring.diameter)
                .offset(layout.ring.offset)
            ForEach(Array(layout.dots.enumerated()), id: \.offset) { _, dot in
                Circle().fill(dot.color.color)
                    .frame(width: dot.diameter, height: dot.diameter)
                    .offset(dot.offset)
            }
        }
        .accessibilityHidden(true)
    }
}

#if DEBUG
#Preview("Default") { SplashView() }
#Preview("Accessibility 3") { SplashView().dynamicTypeSize(.accessibility3) }
#endif
