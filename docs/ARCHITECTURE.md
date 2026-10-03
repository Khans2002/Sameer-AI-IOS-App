# Sameer AI — Architecture v0.1

## Product boundary

Sameer AI is a private, offline-first conversational assistant for one iPhone 16 Pro. Version 1 is text-first: local chat, local conversation history, model management, and private retrieval of user-approved notes. It is not a camera, social, account, analytics, or cloud-AI app.

## Non-negotiable rules

- No cloud inference, API keys, accounts, telemetry, ads, or remote conversation storage.
- Network access is off by default. An explicit model download is the only planned network action, and can later be transferred from the Mac instead.
- All user data remains inside the app sandbox and is encrypted when the device is protected.
- Every third-party package and model must have a reviewed permissive license before inclusion.

## Recommended technical stack

| Layer | Choice | Reason |
| --- | --- | --- |
| App | SwiftUI, Swift Concurrency | Native iPhone experience and low overhead. |
| Generation runtime | `llama.cpp` (MIT) through a small Swift bridge | Mature GGUF support, Metal acceleration, simple model swapping. |
| Default model | Qwen3 1.7B Instruct, 4-bit GGUF, Apache-2.0 | Strong compact model family with a permissive upstream license. |
| Starter alternate | SmolLM2 1.7B Instruct, 4-bit GGUF, Apache-2.0 | Smaller English-first benchmark/control model. |
| Persistence | SQLite + GRDB (MIT), SQLCipher only if its license is accepted | Durable, queryable local history. Start with iOS file protection; add database encryption after a licensing review. |
| Retrieval, later | SQLite FTS5 first; embeddings and vector search only after V1 | A small personal corpus does not justify early RAG complexity. |
| Embeddings, later | BGE Small English v1.5 (MIT), converted for on-device execution | Compact semantic retrieval candidate. |

## System shape

```text
SwiftUI screens
    ↓
ChatViewModel / App state
    ↓
AssistantService ── prompt construction ── Conversation repository (SQLite)
    ↓                                         ↑
LocalInferenceService ── Swift bridge ── llama.cpp + Metal ── GGUF model
    ↓
Token stream → UI
```

The app never sends prompts, completions, history, or retrieved notes off the device.

## Storage and privacy design

- Store app data under `Application Support/SameerAI/` with `NSFileProtectionComplete`.
- Use the iOS Keychain for a locally generated database key if SQLCipher is adopted.
- Keep models in a separate `Models/` directory; record the model identifier, version, SHA-256, source URL, license, and size.
- Add a one-tap **Erase all local data** action and a model-only deletion action.
- Disable iCloud backup for conversations and model files unless explicitly enabled later.
- Do not request camera, photos, contacts, location, microphone, or tracking permissions in V1.

See `STORAGE_AND_FILES_DESIGN.md` for the user-visible storage inventory and the separately exposed Files workspace. Attachment input may be added after its storage ownership and deletion behavior are implemented.

## Performance and feature controls

The app has a **Performance & Features** control center. Every optional feature has a real capability gate; a switch cannot merely hide an icon while its work continues in the background.

- **Essential Mode** is the one-tap emergency/low-heat profile. It keeps local text chat, turns off visual effects and optional workloads, and applies a shorter generation budget.
- Individual switches govern visual effects, voice conversation, attachment analysis, smart memory, and extended reasoning. Features that are not implemented remain clearly described as future local capabilities rather than pretending to be active.
- The inference, voice, attachment, and retrieval services must read this profile before allocating work. A disabled feature may not access the microphone, process an attachment, index data, or create graphics work.
- On leaving Essential Mode, the app restores the user's previous individual choices instead of guessing.

See `VOICE_AND_DYNAMIC_ISLAND.md` for the future on-device voice plan and the Apple-controlled Dynamic Island behavior.

## Delivery phases

1. **Foundation:** Xcode project, SwiftUI shell, local-only policy, build/test pipeline, journal.
2. **Offline chat:** llama.cpp bridge, bundled/developer-loaded test model, streamed tokens, cancellation, model health screen.
3. **Private memory:** SQLite conversations, rename/delete/export, data erasure, file-protection verification.
4. **Quality:** prompt templates, regression suite, battery/thermal/memory benchmarks on the actual iPhone, accessibility and crash recovery.
5. **Optional retrieval:** manually selected notes, FTS5, then embeddings only if tests prove keyword search insufficient.
6. **Optional voice:** separate decision and license review; it is not in the first build.

## Acceptance criteria for V1

- Airplane-mode chat works after a model is installed.
- No network calls occur during normal use.
- Conversations survive relaunch and can be permanently erased.
- The UI stays responsive while generation streams and can be stopped.
- The app recovers cleanly from low-memory and interrupted generation.
- Tested on the physical iPhone 16 Pro, not only a simulator.

## Decisions deliberately deferred

- Exact GGUF conversion/distributor: verify conversion provenance and checksum before shipping.
- Database encryption package: license and App Store implications require a dedicated review.
- Voice, image, camera, web browsing, and autonomous actions: outside this app's current boundary.
