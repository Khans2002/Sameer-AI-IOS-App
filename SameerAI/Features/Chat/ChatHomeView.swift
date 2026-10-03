import PhotosUI
import SwiftUI
import UniformTypeIdentifiers
import UIKit

struct ChatHomeView: View {
    @EnvironmentObject private var settings: FeatureSettings
    @EnvironmentObject private var history: ConversationHistoryStore
    @State private var searchText = ""
    @State private var selectedConversation: ConversationSummary?
    @State private var showingNewChat = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if settings.essentialModeEnabled {
                    Label("Essential Mode · fast local text chat", systemImage: "bolt.fill")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(SameerTheme.gold)
                        .padding(.vertical, 10).padding(.horizontal, 14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(SameerTheme.gold.opacity(0.1))
                }
                ConversationHistoryView(searchQuery: searchText) { selectedConversation = $0 }
            }
            .padding(.horizontal, 20)
            .background(SameerTheme.black.ignoresSafeArea())
            .navigationTitle("Sameer AI")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .searchable(text: $searchText, prompt: "Search conversations")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Menu {
                        layoutButton(.grid, title: "Grid", icon: "square.grid.2x2")
                        layoutButton(.list, title: "List", icon: "list.bullet")
                        layoutButton(.select, title: "Select", icon: "checkmark.circle")
                    } label: { Image(systemName: "ellipsis.circle") }
                    Button { showingNewChat = true } label: { Image(systemName: "square.and.pencil") }
                        .accessibilityLabel("New chat")
                }
            }
            .navigationDestination(item: $selectedConversation) { ChatConversationView(conversation: $0) }
            .navigationDestination(isPresented: $showingNewChat) { ChatConversationView(conversation: nil) }
        }
    }

    private func layoutButton(_ layout: ConversationLayout, title: String, icon: String) -> some View {
        Button { withAnimation(.snappy) { history.layout = layout } } label: {
            Label(title, systemImage: history.layout == layout ? "checkmark" : icon)
        }
    }
}

private struct ChatConversationView: View {
    let conversation: ConversationSummary?
    @EnvironmentObject private var settings: FeatureSettings
    @EnvironmentObject private var history: ConversationHistoryStore
    @EnvironmentObject private var voiceSample: VoiceSampleController
    @FocusState private var composerFocused: Bool
    @State private var prompt = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showingCamera = false
    @State private var showingFileImporter = false
    @State private var attachmentNames: [String] = []
    @State private var showingVoiceDisabledAlert = false
    @State private var messages: [ChatMessage]

    init(conversation: ConversationSummary?) {
        self.conversation = conversation
        _messages = State(initialValue: conversation.map { [ChatMessage(text: $0.preview, isUser: false, timestamp: $0.updatedAt)] } ?? [])
    }

    private var voiceAvailable: Bool { !settings.essentialModeEnabled && settings.isEnabled(.voiceConversation) }

    var body: some View {
        ZStack {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 14) {
                        if messages.isEmpty {
                            ContentUnavailableView("New private chat", systemImage: "lock", description: Text("Messages stay on this iPhone. Choose a local model to receive real replies."))
                                .padding(.top, 130)
                        } else {
                            ForEach(messages) { ChatBubble(message: $0).id($0.id) }
                        }
                    }
                    .padding(.horizontal, 16).padding(.top, 16)
                    .contentShape(Rectangle())
                    .onTapGesture { composerFocused = false }
                }
                .scrollDismissesKeyboard(.interactively)
                .safeAreaInset(edge: .bottom) {
                    ConversationComposer(prompt: $prompt, selectedPhoto: $selectedPhoto, showingCamera: $showingCamera, showingFileImporter: $showingFileImporter, attachmentNames: attachmentNames, voiceAvailable: voiceAvailable, isFocused: $composerFocused, onSend: sendMessage, onVoice: startVoice)
                        .padding(.horizontal, 16).padding(.vertical, 9)
                        .background(.ultraThinMaterial.opacity(0.9))
                }
                .onChange(of: messages.count) { _, _ in
                    if let last = messages.last { withAnimation(.snappy) { proxy.scrollTo(last.id, anchor: .bottom) } }
                }
            }
            if voiceSample.phase != .idle {
                VoiceExperienceOverlay(phase: voiceSample.phase, onStop: voiceSample.stop)
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
        .background(SameerTheme.black.ignoresSafeArea())
        .navigationTitle(conversation?.title ?? "New chat")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showingCamera) { CameraPicker { saveCameraImage($0) }.ignoresSafeArea() }
        .fileImporter(isPresented: $showingFileImporter, allowedContentTypes: [.image, .pdf, .plainText], allowsMultipleSelection: false) { result in
            guard case .success(let urls) = result, let url = urls.first else { return }
            saveImportedFile(url)
        }
        .onChange(of: selectedPhoto) { _, item in
            guard let item else { return }
            Task { await savePhoto(item) }
        }
        .alert("Voice Conversation is off", isPresented: $showingVoiceDisabledAlert) {
            Button("OK", role: .cancel) {}
        } message: { Text("Turn on Voice Conversation in Settings before starting a voice session.") }
    }

    private func sendMessage() {
        let text = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        messages.append(ChatMessage(text: text, isUser: true, timestamp: .now))
        history.addConversation(from: text, attachmentCount: attachmentNames.count)
        prompt = ""; attachmentNames.removeAll(); composerFocused = false
    }

    private func startVoice() {
        guard voiceAvailable else { showingVoiceDisabledAlert = true; return }
        composerFocused = false
        voiceSample.start()
    }

    private func savePhoto(_ item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self) else { return }
        let name = "Photo-\(UUID().uuidString.prefix(8)).jpg"
        guard (try? data.write(to: AppDirectories.attachments.appendingPathComponent(name), options: .atomic)) != nil else { return }
        attachmentNames.append(name); selectedPhoto = nil
    }

    private func saveCameraImage(_ image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.88) else { return }
        let name = "Camera-\(UUID().uuidString.prefix(8)).jpg"
        guard (try? data.write(to: AppDirectories.attachments.appendingPathComponent(name), options: .atomic)) != nil else { return }
        attachmentNames.append(name)
    }

    private func saveImportedFile(_ sourceURL: URL) {
        let hasAccess = sourceURL.startAccessingSecurityScopedResource()
        defer { if hasAccess { sourceURL.stopAccessingSecurityScopedResource() } }
        let name = sourceURL.lastPathComponent
        let destination = AppDirectories.imports.appendingPathComponent(name)
        if !FileManager.default.fileExists(atPath: destination.path) { try? FileManager.default.copyItem(at: sourceURL, to: destination) }
        attachmentNames.append(name)
    }
}

private struct ConversationComposer: View {
    @Binding var prompt: String
    @Binding var selectedPhoto: PhotosPickerItem?
    @Binding var showingCamera: Bool
    @Binding var showingFileImporter: Bool
    let attachmentNames: [String]
    let voiceAvailable: Bool
    var isFocused: FocusState<Bool>.Binding
    let onSend: () -> Void
    let onVoice: () -> Void
    private var hasText: Bool { !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            if !attachmentNames.isEmpty {
                Text("Attached: \(attachmentNames.joined(separator: ", "))")
                    .font(.caption2).foregroundStyle(SameerTheme.secondary).lineLimit(1).padding(.horizontal, 5)
            }
            HStack(alignment: .bottom, spacing: 9) {
                attachmentMenu
                HStack(alignment: .bottom, spacing: 7) {
                    TextField("Ask Sameer AI", text: $prompt, axis: .vertical)
                        .focused(isFocused).lineLimit(1...5).textInputAutocapitalization(.sentences).submitLabel(.send)
                        .onSubmit { if hasText { onSend() } }
                    if hasText {
                        Button(action: onSend) {
                            Image(systemName: "arrow.up").font(.headline.weight(.semibold)).frame(width: 36, height: 36)
                                .background(SameerTheme.white, in: Circle()).foregroundStyle(SameerTheme.black)
                        }.transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.leading, 14).padding(.trailing, hasText ? 6 : 14).padding(.vertical, 7)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .animation(.snappy, value: hasText)
                if !hasText {
                    Button(action: onVoice) {
                        Image(systemName: "waveform").font(.headline.weight(.semibold)).frame(width: 44, height: 44)
                            .background(voiceAvailable ? SameerTheme.blue : SameerTheme.graphite, in: Circle()).foregroundStyle(SameerTheme.white)
                    }
                    .accessibilityLabel("Start voice assistant")
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
    }

    private var attachmentMenu: some View {
        Menu {
            PhotosPicker(selection: $selectedPhoto, matching: .images) { Label("Choose photo", systemImage: "photo") }
            Button { showingCamera = true } label: { Label("Take photo", systemImage: "camera") }
            Button { showingFileImporter = true } label: { Label("Choose file", systemImage: "folder") }
        } label: {
            Image(systemName: "plus").font(.headline.weight(.medium)).frame(width: 44, height: 44)
                .background(.ultraThinMaterial, in: Circle())
        }.accessibilityLabel("Add photo, camera image, or file")
    }
}

private struct ChatMessage: Identifiable {
    let id = UUID(); let text: String; let isUser: Bool; let timestamp: Date
}

private struct ChatBubble: View {
    let message: ChatMessage
    var body: some View {
        HStack {
            if message.isUser { Spacer(minLength: 60) }
            Text(message.text).font(.body).foregroundStyle(SameerTheme.white).padding(13)
                .background(message.isUser ? SameerTheme.blue.opacity(0.68) : SameerTheme.elevated, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            if !message.isUser { Spacer(minLength: 60) }
        }
    }
}

private struct VoiceExperienceOverlay: View {
    let phase: VoiceSamplePhase
    let onStop: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            SameerTheme.black.opacity(0.97).ignoresSafeArea()
            VStack(spacing: 28) {
                VoiceGlassOrb(phase: phase, reduceMotion: reduceMotion)
                    .frame(width: 308, height: 176)
                VStack(spacing: 7) {
                    Text(phase.title).font(.title2.weight(.medium))
                    Text("Sameer AI voice stays private on this iPhone")
                        .font(.subheadline).foregroundStyle(SameerTheme.secondary)
                }
                Button("Stop voice", action: onStop)
                    .font(.body.weight(.medium))
                    .foregroundStyle(SameerTheme.gold)
            }
        }
        .accessibilityAddTraits(.isModal)
    }
}

private struct VoiceGlassOrb: View {
    let phase: VoiceSamplePhase
    let reduceMotion: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: reduceMotion ? 1 : 1.0 / 24.0)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            ZStack {
                Ellipse()
                    .fill(RadialGradient(colors: [.white.opacity(0.18), SameerTheme.blue.opacity(0.45), SameerTheme.black], center: .top, startRadius: 2, endRadius: 175))
                Ellipse()
                    .stroke(LinearGradient(colors: [SameerTheme.gold, .white.opacity(0.9), SameerTheme.blue, SameerTheme.gold], startPoint: .leading, endPoint: .trailing), lineWidth: 2)
                VoiceRibbon(offset: -0.20, amplitude: 0.26, phase: time * 1.5)
                    .stroke(SameerTheme.blue, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .blur(radius: 1.2)
                VoiceRibbon(offset: 0.02, amplitude: 0.18, phase: time * 1.5 + 1.2)
                    .stroke(.white.opacity(0.95), style: StrokeStyle(lineWidth: 3.4, lineCap: .round))
                VoiceRibbon(offset: 0.20, amplitude: phase == .thinking ? 0.36 : 0.25, phase: time * 1.5 + 2.5)
                    .stroke(SameerTheme.gold, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .blur(radius: 1)
                Circle().fill(.white).frame(width: 9, height: 9).blur(radius: 5)
            }
        }
        .accessibilityLabel(phase.title)
    }
}

private struct VoiceRibbon: Shape {
    let offset: CGFloat
    let amplitude: CGFloat
    let phase: Double

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let midY = rect.midY + rect.height * offset
        path.move(to: CGPoint(x: rect.minX + 4, y: midY))
        let first = CGPoint(x: rect.width * 0.30, y: midY - rect.height * amplitude * CGFloat(sin(phase)))
        let second = CGPoint(x: rect.width * 0.68, y: midY + rect.height * amplitude * CGFloat(cos(phase)))
        path.addCurve(to: CGPoint(x: rect.maxX - 4, y: midY), control1: first, control2: second)
        return path
    }
}

private struct CameraPicker: UIViewControllerRepresentable {
    let onImage: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss
    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController(); picker.sourceType = .camera; picker.cameraCaptureMode = .photo; picker.delegate = context.coordinator; return picker
    }
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraPicker; init(parent: CameraPicker) { self.parent = parent }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { parent.dismiss() }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage { parent.onImage(image) }; parent.dismiss()
        }
    }
}

private struct VoiceSampleWave: View {
    let phase: VoiceSamplePhase; let reduceMotion: Bool
    var body: some View {
        TimelineView(.animation(minimumInterval: reduceMotion || phase == .idle ? 1 : 1.0 / 24.0)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            HStack(spacing: 4) {
                ForEach(0..<7, id: \.self) { index in
                    Capsule().fill(LinearGradient(colors: [SameerTheme.blue, .white, SameerTheme.gold], startPoint: .top, endPoint: .bottom))
                        .frame(width: 3, height: phase == .idle ? 8 : 10 + abs(sin(time * 3 + Double(index))) * 22)
                }
            }
        }.accessibilityLabel(phase.title)
    }
}
