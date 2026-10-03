# Sameer AI — Private Development Journal

This is the engineering journal for the app, not an in-app user journal. Add one dated entry for every meaningful decision, experiment, dependency change, model evaluation, privacy review, and release.

## Entry template

```md
## YYYY-MM-DD — Short title

**Goal:**
**What changed / what was tested:**
**Result and evidence:**
**Privacy impact:**
**License impact:**
**Decision:**
**Next step:**
```

## 2026-10-02 — Project discovery and initial architecture

**Goal:** Establish a private, fully local foundation for Sameer AI on iPhone.

**What changed / what was tested:** Confirmed Xcode 27.0, Swift, iPhoneOS SDK 27.0, and iOS Simulator SDK 27.0 are installed. Reviewed current documentation for llama.cpp, MLC LLM, ExecuTorch, WhisperKit, Qwen3, SmolLM2, BGE, and SQLite vector options.

**Result and evidence:** `llama.cpp` has Apple Metal and Swift/iOS support. MLC LLM and ExecuTorch are credible alternatives, but have a heavier initial integration path. Qwen3 1.7B and SmolLM2 1.7B upstream model cards identify Apache-2.0 licenses. The workspace was empty and is not yet a Git repository. About 20 GB of startup disk capacity is free, which is enough to begin but should be expanded before collecting multiple models and build archives.

**Privacy impact:** The proposed V1 has no backend, analytics, account, or cloud inference. Model downloading must be user initiated.

**License impact:** Do not assume a GGUF conversion inherits the upstream model license without checking the conversion repository's license, notices, and checksum. Record all third-party notices before distribution.

**Decision:** Use native SwiftUI plus llama.cpp as the initial architecture; start text-first and defer voice, camera, retrieval embeddings, and web access.

**Next step:** Create the Xcode project and a minimal offline UI, then integrate a test model without committing large model files to Git.

## 2026-10-02 — Open-source stack review, including Chinese projects

**Goal:** Choose a minimal, auditable V1 stack rather than accumulating many AI libraries.

**What changed / what was tested:** Compared llama.cpp, Alibaba MNN, MLC LLM, and ExecuTorch for local iOS inference. Reviewed Alibaba Qwen3, Alibaba Qwen3 Embedding, DeepSeek-R1-Distill-Qwen-1.5B, and BAAI BGE-M3. Checked GRDB, SQLCipher Community Edition, and Swift Testing licensing and iOS relevance.

**Result and evidence:** Qwen3 and Qwen3 Embedding publish Apache-2.0 licenses; MNN publishes Apache-2.0 and includes an offline iOS LLM chat sample; BGE-M3 publishes an MIT license; DeepSeek R1 Distill Qwen 1.5B publishes MIT terms while retaining its Qwen base provenance. llama.cpp is MIT and offers the most straightforward GGUF/iOS starting path. GRDB is MIT and Swift Testing is Apache-2.0.

**Privacy impact:** V1 remains offline after an explicit model installation. No accounts, cloud inference, analytics, or background model marketplaces will be added.

**License impact:** A model's upstream license is not sufficient proof for a third-party quantized GGUF. The conversion source, notice, checksum, and any added license terms must be recorded before use.

**Decision:** Create `OPEN_SOURCE_SELECTION.md`; use Qwen3 1.7B + llama.cpp as the first benchmark stack, and keep MNN as a measured Chinese-runtime alternative.

**Next step:** Initialize the native Xcode project and create the model-install contract plus an empty local chat interface.

## 2026-10-02 — Storage transparency and Files workspace

**Goal:** Make all Sameer AI storage understandable and removable without exposing private internal data to accidental corruption.

**What changed / what was tested:** Researched current Apple guidance for Files sharing, app document directories, storage-size resource keys, and iOS Data Protection. Designed a two-area storage model: protected internal state plus a clean Files-visible user workspace.

**Result and evidence:** Apple documents that `UIFileSharingEnabled` and `LSSupportsOpeningDocumentsInPlace` expose an app's Documents folder in Files without requiring a File Provider extension. Apple recommends Application Support for support files not intended to be openly visible. File resource keys provide allocated and logical byte counts.

**Privacy impact:** Models, imported attachments, and exports can be user-visible in Files. The raw chat database, indexes, settings, and key material remain private because direct Files edits could corrupt them or expose unnecessary implementation details.

**License impact:** No new third-party open-source dependency is required for V1 storage accounting or Files integration.

**Decision:** Add the Storage section before allowing attachment input, expose `Documents/Sameer AI/` in Apple Files, and have the Storage screen account for both private and visible app data.

**Next step:** Start the Xcode project with an empty Storage screen and `StorageInventoryService` contract, then build model management before actual model inference.

## 2026-10-02 — Native project and Essential Mode foundation

**Goal:** Start a compilable native iPhone app with storage transparency and an enforceable performance-control model.

**What changed / what was tested:** Created the `SameerAI` SwiftUI Xcode project, a Chat/Storage/Settings tab structure, app directories, Files sharing configuration, live storage inventory, safe cache clearing, and persistent feature controls. Added Essential Mode and its workload profile.

**Result and evidence:** The iOS Simulator target builds successfully with Xcode. The controlled development session cannot connect to CoreSimulatorService, so it could not launch a simulator; the build output is valid and the app is ready for a normal Xcode or physical-device run.

**Privacy impact:** The only visible Files workspace is `Documents/Sameer AI`; private data remains in Application Support. No microphone, camera, photos, tracking, cloud, analytics, or network permission has been added.

**License impact:** The first project uses no third-party dependency. It uses only our source code and Apple platform frameworks.

**Decision:** Treat Essential Mode as a capability profile which future services must enforce, not a cosmetic UI preference.

**Next step:** Add model manifests and local model management, then integrate the selected open-source inference runtime.

## 2026-10-02 — Visual review, model library, and future voice status

**Goal:** Make the app reviewable before simulator access is available, and build safe local model-file management before inference integration.

**What changed / what was tested:** Created interactive visual directions for the normal chat, Essential Mode, and private voice experience. Added a Models screen that imports GGUF files through the system file picker, copies them into the Sameer AI Files workspace, records allocated size and SHA-256 fingerprint, and supports deletion. Added an Imports storage category. Researched the official ActivityKit and Dynamic Island requirements.

**Result and evidence:** The app target compiles successfully after model-library changes. Apple Live Activities use ActivityKit plus a WidgetKit extension; Apple controls Dynamic Island visibility and limits combined static/dynamic content to 4 KB.

**Privacy impact:** A model import remains local. The initial model manifest deliberately labels licenses “Review before use”; it does not make a license claim merely from a filename. Future Dynamic Island state contains no transcripts or audio.

**License impact:** Model-library code uses only Apple platform APIs. No model or open-source runtime has been imported yet.

**Decision:** The user sees and approves visual direction before voice implementation. Voice/Dynamic Island remains a later opt-in feature after an on-device speech stack review.

**Next step:** Establish the signed model manifest format and verify a first Qwen GGUF source before adding llama.cpp.

## 2026-10-03 — Black, white, gold, and blue visual direction

**Goal:** Replace the starter lavender/indigo interface with a distinctive Sameer AI visual identity inspired by the user's supplied dark metallic reference, while retaining accessibility and Essential Mode clarity.

**What changed / what was tested:** Added a native dark theme with black/graphite surfaces, white text, warm gold, electric blue, and restrained ember highlights. Rebuilt the chat landing screen around an original animated signal instead of a static sparkle. It uses layered native gradients and rotating arcs, with a static Essential Mode version and reduced-motion support. Updated tab, Storage, and Settings surfaces to use the dark theme.

**Result and evidence:** The Simulator build succeeds after the redesign. The animation is an original Sameer AI signal; it does not use Siri artwork or copied UI assets.

**Privacy impact:** No new permission, network use, attachment, or data storage behavior was introduced.

**License impact:** The visual system uses only our SwiftUI code and system symbols; no external visual asset or dependency was added.

**Decision:** Use black and white as the foundation, reserve gold and electric blue for active states, and use the prismatic warm/cool edge only inside the Sameer AI signal. Do not use lavender.

**Next step:** Review the redesign in the completed iOS Simulator, then proceed with signed Qwen model metadata and llama.cpp integration.

## 2026-10-03 — Conversation history and private voice surface

**Goal:** Replace the chat landing animation with a useful conversation history and establish the native foundation for a future private voice status in Dynamic Island.

**What changed / what was tested:** Replaced the landing animation with modular conversation-history UI. It provides persistent Grid, List, and Select modes; grid uses a two-column SwiftUI `LazyVGrid`, and list/select use `LazyVStack`. Added a WidgetKit extension and ActivityKit contract for the Sameer AI voice state, including a black-glass, gold-and-blue Dynamic Island presentation derived from the user's visual direction.

**Result and evidence:** The app and its widget extension build successfully for the iOS Simulator SDK. History contents remain sample data until the local conversation database is connected. The Dynamic Island surface is an ActivityKit view, ready for a future opt-in voice service; it contains only state labels, never transcript text or audio.

**Privacy impact:** No microphone permission, audio capture, transcript, cloud connection, or background audio was added. A future voice session must request microphone permission at the moment it is enabled.

**License impact:** This milestone uses native SwiftUI, ActivityKit, and WidgetKit only. No third-party visual asset or dependency was introduced.

**Decision:** Keep the primary home focused on conversations. Treat Dynamic Island as concise voice-session status rather than a place to expose private content, and respect the operating system's control over whether it is displayed.

**Next step:** Review Grid, List, and Select modes in Simulator. Then connect local chat persistence, select and benchmark the on-device inference runtime, and implement the voice service behind the existing opt-in control.

## 2026-10-03 — On-device voice preview test path

**Goal:** Make the first Dynamic Island and spoken-response experience testable on the user's physical iPhone without falsely presenting a microphone simulation as a real voice assistant.

**What changed / what was tested:** Connected the opt-in Voice Conversation setting to the chat entry point. Added an on-device preview sequence: ready, thinking, then locally synthesized spoken reply. The sequence updates the associated Live Activity and returns the audio session to its prior availability at the end.

**Result and evidence:** The sample does not request microphone permission, record sound, store audio, or make a network connection. It is intentionally a UI, audio-output, and Dynamic Island integration test; real private speech recognition will be added only after choosing and benchmarking the open-source speech stack.

**Privacy impact:** No voice input leaves or is retained by the app. Audio output uses the system's local speech-synthesis service.

**License impact:** This milestone still adds no third-party dependency; it uses Apple AVFoundation, ActivityKit, and WidgetKit.

**Decision:** A feature toggle must disable the sample itself, rather than merely changing its appearance. The preview explicitly says that it is not recording so that its state labels are truthful.

**Next step:** Run the preview on iPhone 16 Pro, verify the Dynamic Island state progression, then choose the open-source on-device speech-recognition implementation.

## 2026-10-03 — Private history persistence foundation

**Goal:** Ensure that conversation-history actions remain local and survive an app relaunch before connecting real model-generated conversations.

**What changed / what was tested:** Added an atomic JSON snapshot for active and archived conversation summaries in the protected Application Support area. Grid, List, Select, delete, and archive actions now work against this persisted state rather than a launch-only in-memory array.

**Result and evidence:** The iPhoneOS build succeeds after the change. The stored file remains private; only the user-facing Models, Attachments, Imports, and Exports folders are exposed in Files.

**Privacy impact:** Titles and previews are private app data, not Files-visible documents. No network, analytics, or external synchronization is involved.

**License impact:** No new dependency; persistence uses Foundation Codable and atomic file writing.

**Decision:** Use this small local repository temporarily. Replace it with the planned encrypted conversation database when real messages, attachments, search, and migrations arrive.

**Next step:** Test select/archive/delete persistence on iPhone, then implement the real chat message model and selected open-source inference runtime.

## 2026-10-03 — Chat composer and Dynamic Island visual revision

**Goal:** Turn the history screen into a usable chat entry point and revise the voice Live Activity to reflect the user's gold, white, and electric-blue glass-orb direction.

**What changed / what was tested:** Replaced the voice-only bottom entry with a native multi-line composer. Its plus menu opens the system photo picker, camera, or file picker. Its right action changes from a voice button when empty to Send when text exists. Camera images and chosen photo/file attachments are saved locally. Revised the Live Activity with an original black-glass capsule, metallic rim, central light bloom, and layered gold/white/blue ribbons.

**Result and evidence:** The iPhoneOS build succeeds. Sending a draft creates a private persisted history record, allowing the UI flow to be tested before the local language model is connected.

**Privacy impact:** Camera permission is requested only after the user chooses Take photo. Files and photos are copied into the app's local workspace. The current voice preview still records nothing and sends nothing to a server.

**License impact:** The composer and Dynamic Island visuals use original SwiftUI/UIKit code and Apple system pickers; no third-party visual asset or dependency was introduced.

**Decision:** Keep the Dynamic Island artwork abstract and original rather than imitating Apple's proprietary Siri artwork. The user's reference directs its warm/cool glass palette and layered-ribbon energy.

**Next step:** Install this build on iPhone 16 Pro and verify the system Live Activity setting. Then implement the local language-model adapter and real conversation detail view.

## 2026-10-03 — History-first navigation and source versioning

**Goal:** Separate the conversation library from the active chat experience, and preserve the project in the user-created GitHub repository.

**What changed / what was tested:** Moved the composer out of the history screen. The history screen now has search, Grid/List/Select, and New Chat. Opening a card or New Chat opens a dedicated chat screen with separate liquid-glass plus, input, and voice controls. When text is entered, the separate voice control transitions away and the Send button appears inside the expanded input surface. Tapping the conversation dismisses the keyboard. Initialized Git and pushed the initial project commit to the user-provided private repository.

**Result and evidence:** The iPhoneOS build succeeds. GitHub `main` now tracks commit `e24225a` as the first project baseline.

**Privacy impact:** Version control contains source and design documentation only. Model files, Derived Data, local Files workspace contents, and user conversations are excluded.

**License impact:** No new open-source library was added.

**Decision:** Start the voice preview directly from the dedicated chat screen; do not require a bottom-sheet confirmation. The iOS system still determines the exact Dynamic Island presentation and user settings can disable Live Activities.

**Next step:** Push the navigation revision, then integrate and benchmark the selected local LLM runtime before downloading a test GGUF.

## 2026-10-03 — Single voice experience and platform boundary

**Goal:** Remove the duplicate in-app voice status bar and make the foreground voice presentation follow the user's glass-orb reference as closely as public iOS APIs allow.

**What changed / what was tested:** Replaced the in-chat status bar with a single full-screen Sameer AI voice experience: a black glass orb with animated gold, white, and electric-blue ribbons. The existing Live Activity continues to provide the system-controlled Dynamic Island/home-screen status when iOS shows it.

**Result and evidence:** The iPhoneOS build succeeds. The app now has one foreground voice visual instead of a second status-card design.

**Privacy impact:** No microphone recording or network behavior was added.

**License impact:** The visual is original native SwiftUI code. It is inspired by the user-provided palette and motion direction, not copied Siri artwork.

**Decision:** Stop attempting to reproduce the proprietary Siri/Dynamic Island animation. Third-party apps cannot replace, animate, or force the system Dynamic Island while foregrounded. Prioritize the local LLM runtime, which provides the app's actual private-assistant value.

**Next step:** Commit this revision and begin the text-first on-device inference integration.
