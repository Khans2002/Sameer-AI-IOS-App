import SwiftUI

@main
struct SameerAIApp: App {
    @StateObject private var featureSettings = FeatureSettings()
    private let storageInventory = StorageInventoryService()
    private let modelLibrary = ModelLibrary()
    private let conversationHistory = ConversationHistoryStore()
    @StateObject private var voiceSample = VoiceSampleController()

    init() {
        AppDirectories.prepare()
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(featureSettings)
                .environmentObject(storageInventory)
                .environmentObject(modelLibrary)
                .environmentObject(conversationHistory)
                .environmentObject(voiceSample)
                .preferredColorScheme(.dark)
        }
    }
}
