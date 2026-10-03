import ActivityKit
import Foundation

struct SameerVoiceActivityAttributes: ActivityAttributes, Sendable {
    struct ContentState: Codable, Hashable, Sendable {
        enum SessionState: String, Codable, Hashable, Sendable {
            case listening
            case thinking
            case speaking
            case paused

            var label: String { rawValue.capitalized }
        }

        let state: SessionState
        let startedAt: Date
    }

    let sessionID: UUID
}
