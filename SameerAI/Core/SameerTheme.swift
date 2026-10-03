import SwiftUI

enum SameerTheme {
    static let black = Color(red: 0.02, green: 0.02, blue: 0.025)
    static let graphite = Color(red: 0.075, green: 0.075, blue: 0.085)
    static let elevated = Color(red: 0.115, green: 0.115, blue: 0.13)
    static let white = Color.white
    static let secondary = Color(red: 0.67, green: 0.67, blue: 0.7)
    static let gold = Color(red: 0.93, green: 0.64, blue: 0.19)
    static let blue = Color(red: 0.35, green: 0.78, blue: 1.0)
    static let ember = Color(red: 1.0, green: 0.33, blue: 0.12)
}

struct SameerSignalView: View {
    let isAnimating: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: isAnimating ? 1.0 / 30.0 : 1.0)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            let pulse = isAnimating ? 0.92 + 0.08 * sin(time * 2.2) : 1.0
            let rotation = isAnimating ? time * 14 : 0

            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [SameerTheme.blue.opacity(0.42), SameerTheme.gold.opacity(0.14), .clear],
                            center: .center,
                            startRadius: 4,
                            endRadius: 122
                        )
                    )
                    .scaleEffect(pulse)

                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .trim(from: 0.08 + Double(index) * 0.09, to: 0.47 + Double(index) * 0.08)
                        .stroke(
                            AngularGradient(
                                colors: [SameerTheme.blue, .white.opacity(0.9), SameerTheme.gold, SameerTheme.ember.opacity(0.7), SameerTheme.blue],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: CGFloat(3 - index), lineCap: .round)
                        )
                        .rotationEffect(.degrees(rotation * Double(index + 1) * (index.isMultiple(of: 2) ? 1 : -1)))
                        .scaleEffect(1 - CGFloat(index) * 0.14)
                        .opacity(0.86 - Double(index) * 0.18)
                }

                Circle()
                    .fill(.black.opacity(0.74))
                    .padding(43)
                Image(systemName: isAnimating ? "waveform" : "bolt.fill")
                    .font(.system(size: 25, weight: .medium))
                    .foregroundStyle(isAnimating ? SameerTheme.white : SameerTheme.gold)
            }
            .accessibilityLabel(isAnimating ? "Sameer AI is ready" : "Essential Mode")
        }
    }
}
