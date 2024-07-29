//
//  SettingsView.swift
//  visionos-example
//
//  Created by coji on 2024/07/29.
//

import SwiftUI

struct SettingsView: View {
  @Bindable var speechRecognition: SpeechRecognition
  @State private var apiKey: String = ApiKeyService.getApiKey() ?? ""
  var onClose: () -> Void

  var body: some View {
    VStack(alignment: .leading) {
      Section("Recognition") {
        Toggle("On Device Recognition", isOn: $speechRecognition.isOnDevice)
      }

      Section("Translation") {
        TextField("Hoge", text: $apiKey)
          .onSubmit {
            ApiKeyService.saveApiKey(apiKey)
          }
      }

      Button(
        "OK",
        action: {
          saveSettings()
          onClose()
        }
      )
    }
    .padding()
  }

  func saveSettings() {
    ApiKeyService.saveApiKey(apiKey)
  }
}

#Preview {
  SettingsView(
    speechRecognition: SpeechRecognition(),
    onClose: {
      print("closed")
    }
  )
}
