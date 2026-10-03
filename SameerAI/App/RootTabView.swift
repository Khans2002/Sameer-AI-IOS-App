import SwiftUI

struct RootTabView: View {
    @EnvironmentObject private var settings: FeatureSettings

    var body: some View {
        TabView {
            ChatHomeView()
                .tabItem { Label("Chat", systemImage: "bubble.left.and.bubble.right") }

            StorageView()
                .tabItem { Label("Storage", systemImage: "externaldrive") }

            PerformanceSettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .tint(settings.essentialModeEnabled ? SameerTheme.gold : SameerTheme.blue)
        .toolbarBackground(SameerTheme.black, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}
