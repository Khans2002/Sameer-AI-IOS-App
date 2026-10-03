import SwiftUI

struct PerformanceSettingsView: View {
    @EnvironmentObject private var settings: FeatureSettings

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Essential Mode", isOn: Binding(
                        get: { settings.essentialModeEnabled },
                        set: { settings.setEssentialMode($0) }
                    ))
                    Text("For heat, battery, or urgent situations. Keeps fast local text chat and turns off optional high-demand features and visual effects.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } header: {
                    Label("Performance", systemImage: "bolt.circle")
                }

                Section {
                    ForEach(Feature.allCases) { feature in
                        Toggle(isOn: Binding(
                            get: { settings.isEnabled(feature) },
                            set: { settings.setEnabled($0, for: feature) }
                        )) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(feature.title)
                                Text(feature.detail)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .disabled(settings.essentialModeEnabled)
                    }
                } header: {
                    Text("Feature controls")
                } footer: {
                    Text(settings.essentialModeEnabled ? "Essential Mode is controlling these settings." : "Only installed features appear active. Future tools remain local and opt-in.")
                }

                Section {
                    LabeledContent("Chat output limit", value: "\(settings.generationTokenLimit) tokens")
                    Text("Later, the inference engine will read this profile before generating a reply. A toggle is never just visual; it must change real workload.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("How it works")
                }
            }
            .navigationTitle("Performance & Features")
            .scrollContentBackground(.hidden)
            .background(SameerTheme.black)
        }
    }
}
