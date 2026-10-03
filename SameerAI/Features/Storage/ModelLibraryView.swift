import SwiftUI
import UniformTypeIdentifiers

struct ModelLibraryView: View {
    @EnvironmentObject private var library: ModelLibrary
    @EnvironmentObject private var storage: StorageInventoryService
    @StateObject private var viewState = ModelLibraryViewState()

    var body: some View {
        List {
            Section {
                Button { viewState.isImporting = true } label: {
                    Label("Install GGUF model", systemImage: "plus.circle.fill")
                }
                Text("The model stays in Files → On My iPhone → Sameer AI → Models. Before using it, we record its SHA-256 fingerprint and size.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Installed models") {
                if library.models.isEmpty {
                    ContentUnavailableView("No model installed", systemImage: "cpu", description: Text("Install a verified GGUF model to enable private local chat."))
                } else {
                    ForEach(library.models) { model in
                        VStack(alignment: .leading, spacing: 5) {
                            Text(model.displayName).font(.headline)
                            Text(ByteCountFormatter.string(fromByteCount: model.byteCount, countStyle: .file))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("SHA-256 \(model.sha256.prefix(12))…")
                                .font(.caption2.monospaced())
                                .foregroundStyle(.secondary)
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                try? library.remove(model)
                                storage.refresh()
                            } label: { Label("Delete", systemImage: "trash") }
                        }
                    }
                }
            }
        }
        .navigationTitle("Models")
        .fileImporter(isPresented: $viewState.isImporting, allowedContentTypes: [.data]) { result in
            switch result {
            case .success(let url):
                do {
                    try library.importModel(from: url)
                    storage.refresh()
                } catch {
                    viewState.importError = error.localizedDescription
                }
            case .failure(let error):
                viewState.importError = error.localizedDescription
            }
        }
        .alert("Model import failed", isPresented: Binding(get: { viewState.importError != nil }, set: { if !$0 { viewState.importError = nil } })) {
            Button("OK", role: .cancel) { viewState.importError = nil }
        } message: {
            Text(viewState.importError ?? "Unknown error")
        }
    }
}

private final class ModelLibraryViewState: ObservableObject {
    @Published var isImporting = false
    @Published var importError: String?
}
