import SwiftUI

struct TranslatorView: View {
    @StateObject private var speechRecognition = SpeechRecognition()
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            HStack {
                LanguageView(title: "English", text: speechRecognition.transcript)
                LanguageView(title: "Japanese", text: speechRecognition.translated)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .navigationTitle("Speech Translator")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack {
                        RecordingButton(speechRecognition: speechRecognition)
                        SettingsButton(showingSettings: $showingSettings)
                    }
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(speechRecognition: speechRecognition, onClose: { showingSettings.toggle() })
        }
    }
}

// MARK: - Subviews
private extension TranslatorView {
    struct LanguageView: View {
        let title: String
        let text: String

        var body: some View {
            VStack {
              HStack {
                  Spacer()
                  Text(title).font(.title2)
                  Spacer()
                  CopyButton(textToCopy: text)
              }
              TextView(text: text)
                    .padding(.bottom)
            }
            .padding(.horizontal)
        }
    }

    struct CopyButton: View {
        let textToCopy: String

        var body: some View {
            Button(action: {
                UIPasteboard.general.string = textToCopy
            }) {
                Label("Copy", systemImage: "clipboard")
            }
        }
    }

    struct RecordingButton: View {
        @ObservedObject var speechRecognition: SpeechRecognition

        var body: some View {
            if speechRecognition.isRecording {
                HStack {
                    Button(action: { speechRecognition.stopTranscribing() }) {
                        Label("音声認識中", systemImage: "stop.fill")
                            .labelStyle(.titleAndIcon)
                    }
                    RecordingSign()
                }
            } else {
                Button(action: { speechRecognition.startTranscribing() }) {
                    Label("音声認識を開始", systemImage: "text.bubble")
                        .labelStyle(.titleAndIcon)
                }
            }
        }
    }

    struct SettingsButton: View {
        @Binding var showingSettings: Bool

        var body: some View {
            Button(action: { showingSettings = true }) {
                Label("設定", systemImage: "slider.horizontal.3")
                    .labelStyle(.titleAndIcon)
            }
        }
    }

    struct RecordingSign: View {
        var body: some View {
            Circle()
                .fill(Color.red)
                .frame(width: 48, height: 48)
        }
    }
}

#Preview {
    TranslatorView()
}
