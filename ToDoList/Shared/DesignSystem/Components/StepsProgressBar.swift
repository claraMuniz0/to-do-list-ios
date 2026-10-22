import SwiftUI

/// Geometry, colors and spoken text of `StepsProgressBar`. Pure so it can be unit tested.
struct StepsProgressBarStyle: Equatable {
    static let height: CGFloat = 6
    static let cornerRadius: CGFloat = 3
    static let trackColor = DSColor.border
    static let fillColor = DSColor.accent

    let progress: StepsProgress

    /// Share of the track that is filled, kept inside 0...1 so bad input never overflows the track.
    var fillFraction: Double { min(max(progress.fraction, 0), 1) }

    func fillWidth(in trackWidth: CGFloat) -> CGFloat { CGFloat(fillFraction) * trackWidth }

    var accessibilityLabel: String { "\(progress.done) of \(progress.total) steps done" }
}

/// Thin track that fills as steps are completed. Callers hide it when there is no progress (zero steps).
struct StepsProgressBar: View {
    let progress: StepsProgress

    private var style: StepsProgressBarStyle { StepsProgressBarStyle(progress: progress) }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: StepsProgressBarStyle.cornerRadius)
                    .fill(StepsProgressBarStyle.trackColor)
                RoundedRectangle(cornerRadius: StepsProgressBarStyle.cornerRadius)
                    .fill(StepsProgressBarStyle.fillColor)
                    .frame(width: style.fillWidth(in: proxy.size.width))
            }
        }
        .frame(height: StepsProgressBarStyle.height)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(style.accessibilityLabel)
    }
}

#if DEBUG
#Preview("No step done") { StepsProgressBar(progress: StepsProgress(done: 0, total: 5)).padding() }
#Preview("2 of 5") { StepsProgressBar(progress: StepsProgress(done: 2, total: 5)).padding() }
#Preview("All done") { StepsProgressBar(progress: StepsProgress(done: 5, total: 5)).padding() }
#endif
