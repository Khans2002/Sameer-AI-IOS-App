import Foundation

struct StorageInventory: Sendable {
    let models: Int64
    let attachments: Int64
    let exports: Int64
    let imports: Int64
    let cache: Int64
    let privateData: Int64
    let availableDeviceStorage: Int64?

    var total: Int64 { models + attachments + exports + imports + cache + privateData }
}

@MainActor
final class StorageInventoryService: ObservableObject {
    @Published private(set) var inventory = StorageInventory(models: 0, attachments: 0, exports: 0, imports: 0, cache: 0, privateData: 0, availableDeviceStorage: nil)

    init() { refresh() }

    func refresh() {
        AppDirectories.prepare()
        inventory = StorageInventory(
            models: directorySize(AppDirectories.models),
            attachments: directorySize(AppDirectories.attachments),
            exports: directorySize(AppDirectories.exports),
            imports: directorySize(AppDirectories.imports),
            cache: directorySize(AppDirectories.cache),
            privateData: directorySize(AppDirectories.privateSupport),
            availableDeviceStorage: availableDeviceStorage()
        )
    }

    func clearCache() {
        try? FileManager.default.removeItem(at: AppDirectories.cache)
        AppDirectories.prepare()
        refresh()
    }

    private func directorySize(_ root: URL) -> Int64 {
        let keys: Set<URLResourceKey> = [.isRegularFileKey, .totalFileAllocatedSizeKey]
        guard let enumerator = FileManager.default.enumerator(at: root, includingPropertiesForKeys: Array(keys), options: [.skipsHiddenFiles]) else { return 0 }
        return enumerator.reduce(Int64(0)) { total, item in
            guard let url = item as? URL,
                  let values = try? url.resourceValues(forKeys: keys),
                  values.isRegularFile == true else { return total }
            return total + Int64(values.totalFileAllocatedSize ?? 0)
        }
    }

    private func availableDeviceStorage() -> Int64? {
        let keys: Set<URLResourceKey> = [.volumeAvailableCapacityForImportantUsageKey]
        let values = try? AppDirectories.visibleWorkspace.resourceValues(forKeys: keys)
        return values?.volumeAvailableCapacityForImportantUsage
    }
}
