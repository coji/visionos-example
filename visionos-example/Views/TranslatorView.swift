//
//  TestView.swift
//  visionos-example
//
//  Created by coji on 2024/07/21.
//

import SwiftUI

struct TranslatorView: View {
  private var speechRecognition = SpeechRecognition()
  @State private var showingSettings = false

  var body: some View {
    NavigationStack {
      VStack(alignment: .leading) {
        HStack {
          VStack {
            HStack {
              Spacer()
              Text("English").font(.title2)
              Spacer()
              Button(action: {
                UIPasteboard.general.string = speechRecognition.transcript
              }) {
                Label("Copy", systemImage: "clipboard")
              }
            }
            TextView(text: speechRecognition.transcript)
              .padding(.bottom)
          }
          .padding(.horizontal)

          VStack {
            HStack {
              Spacer()
              Text("Japanese").font(.title2)
              Spacer()
              Button(action: {
                // UIPasteboard.general.string = speechRecognition.translated
              }) {
                Label("Copy", systemImage: "clipboard")
              }
            }
            TextView(text: "" /*speechRecognition.translated*/)
              .padding(.bottom)
          }
          .padding(.horizontal)
        }
      }
      .frame(maxWidth: .infinity)
      .padding()
      .navigationTitle("Vision Translator")
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          HStack {
            if(self.speechRecognition.isRecording) {
              HStack {
                Button(action: {
                  self.speechRecognition.stopTranscribing()
                }) {
                  Label("音声認識中", systemImage: "stop.fill")
                    .labelStyle(.titleAndIcon)
                }
                RecordingSign()
              }
            } else {
              Button(action: {
                self.speechRecognition.startTranscribing()
              }) {
                Label("音声認識を開始", systemImage: "text.bubble")
                  .labelStyle(.titleAndIcon)
              }
            }
            Button(action: {
              showingSettings = true
            }) {
              Label("設定", systemImage: "slider.horizontal.3")
                .labelStyle(.titleAndIcon)
            }
          }
        }
      }
    }.sheet(isPresented: $showingSettings, content: {
      SettingsView(speechRecognition: speechRecognition, onClose: {
        showingSettings.toggle()
      })
    })
  }
}

struct RecordingSign: View {
  var body: some View {
    Circle().fill(Color.red).frame(width: 48, height: 48)
  }
}

#Preview {
  TranslatorView()
}
