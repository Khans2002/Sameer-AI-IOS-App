# Sameer AI — Open-Source Selection Record

**Reviewed:** 2026-10-02  
**Scope:** private, offline, text-first iPhone application. This document is a decision record, not a claim that every layer of iOS is open source.

## Honest definition of “open source” for this project

Our app code, third-party runtime, model weights, database layer, test code, and documentation will use auditable permissive licenses (preferably MIT, Apache-2.0, BSD, or public domain). iOS, Xcode, SwiftUI, Metal, Keychain, and iPhone hardware are Apple-provided proprietary platform components. A native iPhone app cannot avoid that fact.

We will not use closed AI APIs, cloud inference, Firebase, analytics SDKs, advertising SDKs, or a backend.

## Final V1 stack

| Job | Selected component | License | Why this is selected | What we are not using now |
| --- | --- | --- | --- | --- |
| App interface | Our SwiftUI code | Our code; Apple framework | Small, native, accessible iPhone UI. We own the layout and interaction design. | React Native, Flutter, UI kits: unnecessary runtime and dependencies. |
| App organization | Our own feature-based MVVM / service boundaries | Our code | Clear learning path: UI, state, business rules, storage, inference are separate. | Large architecture frameworks. |
| Text inference | llama.cpp / ggml via a narrow Objective-C++ bridge | MIT | GGUF model format, Apple Metal support, Swift/iOS package path, broad model compatibility, and simplest model-switching workflow. | MLC LLM and ExecuTorch are capable but add compilation/export complexity for our first iOS-only release. |
| First conversation model | Qwen3 1.7B Instruct, 4-bit GGUF from a verified conversion | Apache-2.0 upstream | Alibaba Qwen is a high-quality Chinese open model family, multilingual, and available at a practical 1.7B size. 4-bit quantization makes it suitable for a phone. | Large 4B+ models: first prove responsiveness, thermals, and memory. |
| Fast fallback model | Qwen3 0.6B, 4-bit GGUF | Apache-2.0 | Small benchmark/control model for battery and speed testing. | Treating it as the only model; quality will be lower. |
| Reasoning experiment | DeepSeek-R1-Distill-Qwen-1.5B, 4-bit GGUF | MIT; base Qwen notices retained | A strong Chinese open model to test deliberate reasoning. It is an experiment, not the default, because it can produce long answers and use more battery/time. | Shipping it before device benchmarks. |
| Local chat database | SQLite plus GRDB.swift | SQLite public domain; GRDB MIT | Reliable local relational storage, migrations, search, and concurrency support. | Cloud databases, Firebase, Core Data/SwiftData dependency. |
| Protection at rest | iOS Data Protection (`NSFileProtectionComplete`) and Keychain configuration | Apple platform | Keeps app files unavailable while the phone is locked. This is the correct V1 baseline without adding a fragile crypto stack. | Writing our own encryption; that would be unsafe. |
| Model installer | Our code, HTTPS only after explicit user action | Our code; Apple networking | The app has no normal network traffic. Downloads can instead be transferred from the Mac later. | Automatic model feeds, background syncing, analytics. |
| File integrity | SHA-256 verification in our installer | Our code; Apple platform primitive | Prevents use of a corrupt or substituted model file. | Trusting a filename or a third-party model listing. |
| Testing | Swift Testing plus our deterministic test fixtures | Apache-2.0; our code | Modern open-source Swift test package; supports Apple platforms. | Network-dependent tests. |
| Documentation | Markdown, this journal, architecture and license records | Our code | Long-lived, readable proof of decisions and experiments. | Undocumented choices. |

## Candidate comparison: local LLM runtime

| Candidate | Open license | iOS capability | Decision |
| --- | --- | --- | --- |
| **llama.cpp** | MIT | Swift package declares iOS; includes Metal/Accelerate support and handles GGUF. | **Use first.** Best balance of simple integration and model choice. |
| **MNN** (Alibaba) | Apache-2.0 | Has a dedicated offline iOS LLM Chat sample with CPU/Metal configuration. | **Benchmark in a later spike.** Excellent Chinese alternative; conversion/packaging path is more specialized, so not our first integration. |
| **MLC LLM** | Apache-2.0 | Provides an iOS Swift SDK and compiled model-library workflow. | Keep as an alternative. It is powerful but requires more build tooling and model compilation. |
| **ExecuTorch** | BSD-style | Swift/Objective-C iOS APIs, Core ML and XNNPACK paths. LLM Swift APIs are documented as experimental. | Do not use for V1. Revisit for a future Core ML/ANE performance investigation. |

## Chinese open-model choices

| Job | Candidate | License and fit | Decision |
| --- | --- | --- | --- |
| Daily local assistant | **Qwen3 1.7B** (Alibaba) | Apache-2.0, model family available from 0.6B upward. | **Primary.** |
| Fast / smallest mode | **Qwen3 0.6B** (Alibaba) | Apache-2.0. | Test and offer only if it passes quality checks. |
| Deep reasoning | **DeepSeek-R1-Distill-Qwen-1.5B** (DeepSeek) | MIT, derived from Apache-2.0 Qwen base. | Benchmark-only at first; its reasoning verbosity can hurt mobile experience. |
| Multilingual semantic search, later | **Qwen3-Embedding-0.6B** (Alibaba) | Apache-2.0, 100+ languages, up to 1024 dimensions. | Preferred semantic-retrieval candidate, only after V1 proves the need. |
| Mature multilingual retrieval, later | **BGE-M3** (BAAI, Beijing) | MIT, multilingual and supports dense/sparse/multi-vector retrieval. | Strong research baseline but likely too heavy for the first phone build. |
| Voice, later | FunASR / SenseVoice ecosystem (ModelScope) | Requires a separate model-by-model and iOS-runtime review. | Explicitly out of scope; do not add microphone permission now. |

## Dependency gates — no exceptions

Before a package or model enters the app, record all of the following in `THIRD_PARTY_NOTICES.md`:

1. Exact repository/model URL and immutable version or commit.
2. Full license and required attribution.
3. Direct versus transitive dependencies and their licenses.
4. Model conversion author, source files, SHA-256 hash, quantization method, and test result.
5. Network behavior, iOS permissions, memory use, battery/thermal evidence, and removal path.

Any candidate with an unclear license, opaque binary, hidden network activity, unsupported iOS build, or unacceptable device test is rejected.

## Why not choose “all open-source projects”

There are thousands of relevant repositories and model conversions, and their releases/licenses change. Shipping every option would make the app insecure, enormous, and impossible to maintain. We instead research the viable alternatives per job, choose one small dependency set, lock exact versions, benchmark on the actual iPhone, and re-evaluate only when evidence justifies a change.
