import Foundation

enum Feature: String, CaseIterable, Identifiable {
    case visualEffects
    case voiceConversation
    case attachmentAnalysis
    case semanticMemory
    case extendedReasoning

    var id: String { rawValue }

    var title: String {
        switch self {
        case .visualEffects: "Visual effects"
        case .voiceConversation: "Voice conversation"
        case .attachmentAnalysis: "Photo and document analysis"
        case .semanticMemory: "Smart memory"
        case .extendedReasoning: "Extended reasoning"
        }
    }

    var detail: String {
        switch self {
        case .visualEffects: "Animations and richer visual treatment."
        case .voiceConversation: "Future on-device speech input and spoken replies."
        case .attachmentAnalysis: "Future local processing of selected photos and documents."
        case .semanticMemory: "Future local search across approved chats and notes."
        case .extendedReasoning: "Allows longer, more demanding model responses."
        }
    }
}

@MainActor
final class FeatureSettings: ObservableObject {
    @Published private(set) var essentialModeEnabled: Bool
    @Published private var featureStates: [String: Bool]
    private var savedStatesBeforeEssentialMode: [String: Bool]?

    init(defaults: UserDefaults = .standard) {
        essentialModeEnabled = defaults.bool(forKey: "essentialModeEnabled")
        featureStates = Dictionary(uniqueKeysWithValues: Feature.allCases.map { feature in
            let key = "feature.\(feature.rawValue)"
            return (feature.rawValue, defaults.object(forKey: key) as? Bool ?? Self.defaultValue(for: feature))
        })
        if essentialModeEnabled { applyEssentialMode() }
    }

    func isEnabled(_ feature: Feature) -> Bool { featureStates[feature.rawValue] ?? false }

    func setEnabled(_ enabled: Bool, for feature: Feature) {
        guard !essentialModeEnabled else { return }
        featureStates[feature.rawValue] = enabled
        UserDefaults.standard.set(enabled, forKey: "feature.\(feature.rawValue)")
    }

    func setEssentialMode(_ enabled: Bool) {
        guard enabled != essentialModeEnabled else { return }
        essentialModeEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "essentialModeEnabled")
        if enabled {
            savedStatesBeforeEssentialMode = featureStates
            applyEssentialMode()
        } else if let savedStatesBeforeEssentialMode {
            featureStates = savedStatesBeforeEssentialMode
            persistFeatureStates()
            self.savedStatesBeforeEssentialMode = nil
        }
    }

    var generationTokenLimit: Int { essentialModeEnabled ? 160 : 512 }

    private func applyEssentialMode() {
        Feature.allCases.forEach { featureStates[$0.rawValue] = false }
    }

    private func persistFeatureStates() {
        featureStates.forEach { UserDefaults.standard.set($0.value, forKey: "feature.\($0.key)") }
    }

    private static func defaultValue(for feature: Feature) -> Bool {
        feature == .visualEffects
    }
}
