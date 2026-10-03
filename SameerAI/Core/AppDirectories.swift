import Foundation

enum AppDirectories {
    private static var fileManager: FileManager { FileManager.default }

    static var privateSupport: URL {
        let root = try! fileManager.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        return root.appendingPathComponent("SameerAI", isDirectory: true)
    }

    static var visibleWorkspace: URL {
        let root = try! fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        return root.appendingPathComponent("Sameer AI", isDirectory: true)
    }

    static var cache: URL {
        let root = try! fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        return root.appendingPathComponent("SameerAI", isDirectory: true)
    }

    static var models: URL { visibleWorkspace.appendingPathComponent("Models", isDirectory: true) }
    static var attachments: URL { visibleWorkspace.appendingPathComponent("Attachments", isDirectory: true) }
    static var imports: URL { visibleWorkspace.appendingPathComponent("Imports", isDirectory: true) }
    static var exports: URL { visibleWorkspace.appendingPathComponent("Exports", isDirectory: true) }

    static func prepare() {
        [privateSupport, visibleWorkspace, cache, models, attachments, imports, exports].forEach { directory in
            try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            try? fileManager.setAttributes([.protectionKey: FileProtectionType.complete], ofItemAtPath: directory.path)
        }
    }
}
