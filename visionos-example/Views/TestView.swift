//
//  TestView.swift
//  visionos-example
//
//  Created by coji on 2024/07/21.
//

import SwiftUI

struct TestView: View {
  private var speechRecognition = SpeechRecognition()
  @State private var showingSheet = false

  var body: some View {
    NavigationStack {
      VStack(alignment: .leading) {
        HStack {
          VStack {
            HStack {
              Spacer()
              Text("English").font(.title2)
              Spacer()
              Button("Copy", action: {
                UIPasteboard.general.string = speechRecognition.transcript
              })
            }
            TextView(text: speechRecognition.transcript)
              .padding()
          }

          VStack {
            HStack {
              Spacer()
              Text("Japanese").font(.title2)
              Spacer()
              Button("Copy", action: {
                // UIPasteboard.general.string = speechRecognition.translated
              })
            }
            TextView(text: "" /*speechRecognition.translated*/)
              .padding()
          }
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
                Button("音声認識中", action: {
                  self.speechRecognition.stopTranscribing()
                })
                RecordingSign()
              }
            } else {
              Button("音声認識を開始", action: {
                self.speechRecognition.startTranscribing()
              })
            }
            Button("設定", action: {
              showingSheet = true
            })
          }
        }
      }
    }.sheet(isPresented: $showingSheet, content: {
      @Bindable var speechRecognition = speechRecognition

      VStack {
        Toggle("On Device Recognition", isOn: $speechRecognition.isOnDevice)
        Button("Close", action: {
          showingSheet = false
        })
      }
      .padding()
    })
  }
}

struct RecordingSign: View {
  var body: some View {
    Circle().fill(Color.red).frame(width: 48, height: 48)
  }
}

#Preview {
  TestView()
}
