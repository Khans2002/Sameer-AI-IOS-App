import ActivityKit
import SwiftUI
import WidgetKit

struct SameerVoiceLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SameerVoiceActivityAttributes.self) { context in
            HStack(spacing: 10) {
                SameerVoiceOrb(compact: true, state: context.state.state)
                    .frame(width: 34, height: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Sameer AI")
                        .font(.caption.weight(.medium))
                    Text(context.state.state.label)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(context.state.startedAt, style: .timer)
                    .font(.caption.monospacedDigit())
            }
            .padding(.horizontal, 16)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    SameerVoiceOrb(compact: false, state: context.state.state)
                        .frame(width: 92, height: 48)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 3) {
                        Text("Sameer AI")
                            .font(.headline)
                        Text(context.state.state.label)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 12) {
                        Text(context.state.state == .listening ? "Private voice preview" : "Working locally on iPhone")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer(minLength: 8)
                        Text(context.state.startedAt, style: .timer)
                            .font(.caption.monospacedDigit())
                    }
                    .padding(.top, 6)
                }
            } compactLeading: {
                SameerVoiceOrb(compact: true, state: context.state.state)
                    .frame(width: 28, height: 18)
            } compactTrailing: {
                Image(systemName: context.state.state == .thinking ? "sparkles" : "waveform")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(context.state.state == .thinking ? .orange : .cyan)
            } minimal: {
                Image(systemName: "waveform")
                    .foregroundStyle(.cyan)
            }
            .widgetURL(URL(string: "sameerai://voice"))
            .keylineTint(.orange)
        }
    }
}

private struct SameerVoiceOrb: View {
    let compact: Bool
    let state: SameerVoiceActivityAttributes.ContentState.SessionState

    var body: some View {
        ZStack {
            Capsule()
                .fill(
                    RadialGradient(
                        colors: [.white.opacity(0.17), .blue.opacity(0.38), .black],
                        center: .top,
                        startRadius: 2,
                        endRadius: compact ? 31 : 68
                    )
                )
            Capsule()
                .stroke(
                    LinearGradient(colors: [.orange.opacity(0.9), .white.opacity(0.9), .cyan, .orange], startPoint: .leading, endPoint: .trailing),
                    lineWidth: compact ? 1.5 : 2
                )
            VoiceRibbon(offset: -0.20, amplitude: 0.32)
                .stroke(.cyan.opacity(0.95), style: StrokeStyle(lineWidth: compact ? 1.2 : 2.1, lineCap: .round))
                .blur(radius: compact ? 0.3 : 0.8)
            VoiceRibbon(offset: 0.04, amplitude: 0.21)
                .stroke(.white.opacity(0.95), style: StrokeStyle(lineWidth: compact ? 1.3 : 2.3, lineCap: .round))
            VoiceRibbon(offset: 0.22, amplitude: state == .thinking ? 0.35 : 0.26)
                .stroke(.orange.opacity(0.94), style: StrokeStyle(lineWidth: compact ? 1.2 : 2, lineCap: .round))
                .blur(radius: compact ? 0.2 : 0.7)
            Circle()
                .fill(.white.opacity(state == .thinking ? 0.8 : 0.52))
                .frame(width: compact ? 3 : 6, height: compact ? 3 : 6)
                .blur(radius: compact ? 1 : 3)
        }
        .accessibilityLabel("Sameer AI voice is active")
    }
}

private struct VoiceRibbon: Shape {
    let offset: CGFloat
    let amplitude: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let midY = rect.midY + (rect.height * offset)
        path.move(to: CGPoint(x: rect.minX + 2, y: midY))
        path.addCurve(
            to: CGPoint(x: rect.maxX - 2, y: midY),
            control1: CGPoint(x: rect.width * 0.30, y: midY - rect.height * amplitude),
            control2: CGPoint(x: rect.width * 0.68, y: midY + rect.height * amplitude)
        )
        return path
    }
}
