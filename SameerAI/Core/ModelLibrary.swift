import CryptoKit
import Foundation

struct LocalModel: Codable, Identifiable, Sendable {
    let id: UUID
    let displayName: String
    let fileName: String
    let sourceDescription: String
    let sha256: String
    let byteCount: Int64
    let installedAt: Date
    let license: String
}

@MainActor
final class ModelLibrary: ObservableObject {
    @Published private(set) var models: [LocalModel] = []

    private var manifestURL: URL { AppDirectories.models.appendingPathComponent("model-manifest.json") }

    init() { load() }

    func importModel(from source: URL) throws {
        guard source.pathExtension.lowercased() == "gguf" else {
            throw ModelLibraryError.unsupportedFile
        }

        let isSecurityScoped = source.startAccessingSecurityScopedResource()
        defer { if isSecurityScoped { source.stopAccessingSecurityScopedResource() } }

        let originalName = source.deletingPathExtension().lastPathComponent
        let safeName = originalName.replacingOccurrences(of: "/", with: "-")
        let fileName = uniqueFileName(base: safeName, extension: "gguf")
        let stagingURL = AppDirectories.models.appendingPathComponent(".staging-\(UUID().uuidString).gguf")
        let destination = AppDirectories.models.appendingPathComponent(fileName)

        try FileManager.default.copyItem(at: source, to: stagingURL)
        do {
            let byteCount = try fileSize(at: stagingURL)
            let hash = try sha256(of: stagingURL)
            try FileManager.default.moveItem(at: stagingURL, to: destination)
            try FileManager.default.setAttributes([.protectionKey: FileProtectionType.complete], ofItemAtPath: destination.path)

            let model = LocalModel(
                id: UUID(),
                displayName: originalName,
                fileName: fileName,
                sourceDescription: source.lastPathComponent,
                sha256: hash,
                byteCount: byteCount,
                installedAt: Date(),
                license: "Review before use"
            )
            models.append(model)
            models.sort { $0.installedAt > $1.installedAt }
            try persist()
        } catch {
            try? FileManager.default.removeItem(at: stagingURL)
            throw error
        }
    }

    func remove(_ model: LocalModel) throws {
        try? FileManager.default.removeItem(at: AppDirectories.models.appendingPathComponent(model.fileName))
        models.removeAll { $0.id == model.id }
        try persist()
    }

    private func load() {
        guard let data = try? Data(contentsOf: manifestURL),
              let loaded = try? JSONDecoder().decode([LocalModel].self, from: data) else { return }
        models = loaded.filter { FileManager.default.fileExists(atPath: AppDirectories.models.appendingPathComponent($0.fileName).path) }
    }

    private func persist() throws {
        let data = try JSONEncoder.pretty.encode(models)
        try data.write(to: manifestURL, options: [.atomic])
        try FileManager.default.setAttributes([.protectionKey: FileProtectionType.complete], ofItemAtPath: manifestURL.path)
    }

    private func uniqueFileName(base: String, extension fileExtension: String) -> String {
        var candidate = "\(base).\(fileExtension)"
        var counter = 2
        while FileManager.default.fileExists(atPath: AppDirectories.models.appendingPathComponent(candidate).path) {
            candidate = "\(base)-\(counter).\(fileExtension)"
            counter += 1
        }
        return candidate
    }

    private func fileSize(at url: URL) throws -> Int64 {
        let values = try url.resourceValues(forKeys: [.totalFileAllocatedSizeKey, .fileSizeKey])
        return Int64(values.totalFileAllocatedSize ?? values.fileSize ?? 0)
    }

    private func sha256(of url: URL) throws -> String {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        var hasher = SHA256()
        while let data = try handle.read(upToCount: 1_048_576), !data.isEmpty {
            hasher.update(data: data)
        }
        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }
}

enum ModelLibraryError: LocalizedError {
    case unsupportedFile

    var errorDescription: String? {
        switch self {
        case .unsupportedFile: "Choose a GGUF model file."
        }
    }
}

private extension JSONEncoder {
    static var pretty: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}
