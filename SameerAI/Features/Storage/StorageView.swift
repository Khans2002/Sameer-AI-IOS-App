import SwiftUI

struct StorageView: View {
    @EnvironmentObject private var storage: StorageInventoryService

    var body: some View {
        NavigationStack {
            List {
                Section {
                    LabeledContent("Sameer AI storage", value: ByteCountFormatter.string(fromByteCount: storage.inventory.total, countStyle: .file))
                    if let available = storage.inventory.availableDeviceStorage {
                        LabeledContent("Available on iPhone", value: ByteCountFormatter.string(fromByteCount: available, countStyle: .file))
                    }
                } header: {
                    Label("Storage overview", systemImage: "externaldrive")
                } footer: {
                    Text("Every category is calculated from the app's actual files. No hidden “Other” category.")
                }

                Section("Manage storage") {
                    NavigationLink { ModelLibraryView() } label: {
                        StorageRow(title: "Models", detail: "Installed local AI models", size: storage.inventory.models, icon: "cpu")
                    }
                    StorageRow(title: "Chats and attachments", detail: "Messages, photos, and documents", size: storage.inventory.attachments + storage.inventory.privateData, icon: "bubble.left.and.bubble.right")
                    StorageRow(title: "Exports", detail: "Files you created from chats", size: storage.inventory.exports, icon: "square.and.arrow.up")
                    StorageRow(title: "Imports", detail: "Files waiting for review", size: storage.inventory.imports, icon: "tray.and.arrow.down")
                    Button(role: .destructive) { storage.clearCache() } label: {
                        StorageRow(title: "Temporary files", detail: "Safe to clear", size: storage.inventory.cache, icon: "trash")
                    }
                }

                Section("Files app") {
                    Label("On My iPhone → Sameer AI", systemImage: "folder")
                    Text("Models, attachments, imports, and exports will be visible here. Private chat records and settings remain protected inside the app.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Storage")
            .toolbar { Button("Refresh") { storage.refresh() } }
            .onAppear { storage.refresh() }
            .scrollContentBackground(.hidden)
            .background(SameerTheme.black)
        }
    }
}

private struct StorageRow: View {
    let title: String
    let detail: String
    let size: Int64
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon).frame(width: 22).foregroundStyle(.indigo)
            VStack(alignment: .leading) {
                Text(title)
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text(ByteCountFormatter.string(fromByteCount: size, countStyle: .file)).foregroundStyle(.secondary)
        }
    }
}
