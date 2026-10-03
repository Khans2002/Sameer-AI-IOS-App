# Sameer AI — Storage and Files Design v0.1

## Product promise

Every byte used by Sameer AI is visible in **Settings → Storage**. The user can identify the category, inspect individual large items, and remove anything that is safe to remove. The app also provides a clean **On My iPhone → Sameer AI** folder in Apple Files for models, imported attachments, and exports.

Storage is not hidden behind vague labels such as “Other.” If the app owns it, it is counted and explained.

## Privacy-safe two-area design

| Area | Physical location | Visible in Files | Contents | Why |
| --- | --- | --- | --- | --- |
| Private system area | `Library/Application Support/SameerAI/` | No | SQLite chat database, indexes, settings, encryption/key metadata, internal working state | Files must not be able to edit the database or break chat consistency. |
| User workspace | `Documents/Sameer AI/` | Yes | Models, imported chat attachments, and user exports | The user can inspect, copy, import, or delete their own large files in Apple Files. |
| Rebuildable cache | `Library/Caches/SameerAI/` | No | thumbnails, temporary conversions, incomplete downloads, derived indexes | Can be cleared safely and never contains the only copy of user content. |

The system enables `UIFileSharingEnabled` and `LSSupportsOpeningDocumentsInPlace`, which make the app’s `Documents` folder appear in Files. It does **not** need a File Provider extension because no remote storage or cloud sync is involved.

## Files app folder layout

```text
On My iPhone
└── Sameer AI
    ├── Models
    │   ├── Qwen3-1.7B-Instruct-Q4.gguf
    │   └── model-manifest.json
    ├── Attachments
    │   └── <conversation-id>
    │       ├── 2026-10-02_001_photo.jpg
    │       └── 2026-10-02_002_document.pdf
    ├── Imports
    │   └── Put model files or documents here for Sameer AI to review
    └── Exports
        └── Sameer-AI-Chat-2026-10-02.md
```

Names are understandable; the database uses the stable identifier internally. Every model and attachment has a manifest record with source, SHA-256 hash, size, chat references, and creation time.

## Storage screen

```text
Storage
Sameer AI is using 3.42 GB                         [Manage]

Models                                      2.86 GB   >
Chats and attachments                       431 MB    >
Exports                                      92 MB     >
Temporary files                             37 MB     [Clear]
Private database and indexes                 5 MB     >

Available on iPhone                         41.3 GB
Open Sameer AI folder in Files                         >
```

### Category behavior

| Category | User sees | User can do | Deletion result |
| --- | --- | --- | --- |
| Models | Every installed model, size, version, last used, default status | Delete a model, set default, inspect source and license | Chat history remains. The app cannot use that model until reinstalled. |
| Chats and attachments | Conversations ordered by attachment/storage size; each photo, document, or audio item | Delete attachment, delete chat, export chat | Attachment deletion leaves a clear “attachment removed” placeholder in the chat. Deleting a chat removes text and unreferenced attachments. |
| Exports | Exported Markdown, text, or later PDF files | Preview, share, delete | Only export copy is removed; original chat stays. |
| Temporary files | Thumbnail cache, interrupted download data, rebuildable indexes | Clear all | Safe immediate recovery of space; app regenerates files when needed. |
| Private database and indexes | Exact size with plain-language explanation | Delete individual chat via Chat category, or erase all app data in Privacy settings | Never expose a raw database file for manual editing. |

## Correct accounting rules

- Measure actual allocated bytes, not only logical file sizes, so the total is truthful on APFS.
- Deduplicate attachments by SHA-256. If the same photo is used in multiple chats, store one file and show reference count.
- Count a shared attachment only once in the total; show it in every linked chat with “shared with N chats.”
- Rescan when the app enters the foreground and after returning from Files. If a model or attachment was manually deleted, update the UI rather than crashing.
- Write imported/downloaded files to a temporary location, verify hash and format, then atomically move them into their final folder.
- Protect all user-created files with `NSFileProtectionComplete` when practical. Do not leave private content only in caches.

## User-control flow

1. The user opens **Settings → Storage** and sees the app total plus clear categories.
2. They open **Models** to delete an unused 1.2 GB model, or open **Chats and attachments** to find a chat containing many photos.
3. A destructive action shows the exact effect: “Delete 14 photos (326 MB). This cannot be undone.”
4. The app removes the data, recomputes the size, and reflects the new amount immediately.
5. The user can also manage user-workspace items in **Files → On My iPhone → Sameer AI**. The app reconciles any manual changes when reopened.

## What is deliberately not exposed in Files

- Raw conversation database and search indexes: manual edits would corrupt history.
- Encryption/key material, settings, logs, and temporary inference state.
- A hidden duplicate of a Files-visible model or attachment; storing two copies would defeat the storage feature.

## Implementation order

1. Define the three directories and a `StorageInventoryService` that computes category sizes.
2. Build the Storage overview with real empty-state accounting.
3. Build model manifests, safe installation, verification, and deletion.
4. Add attachment ownership/reference tracking before photo/document input is allowed.
5. Expose the Documents workspace in Files and implement foreground reconciliation.
6. Add exports, cache clearing, storage warnings, and end-to-end deletion tests.

## Test cases that must pass

- A 1 GB model appears exactly once in Storage and is removable from both app and Files.
- A photo used in two chats appears once on disk and remains until the last reference is removed.
- Removing an attachment in Files never crashes the chat; the chat shows a removed-file state.
- Clearing cache cannot delete an original model, attachment, chat, or export.
- Storage totals remain correct after relaunch, low storage, interrupted download, and an app upgrade.
- The Files folder contains no private database or key material.
