//
//  ApiKeyInputView.swift
//  visionos-example
//
//  Created by coji on 2024/07/29.
//

import SwiftUI

struct ApiKeyInputView: View {
  @State private var apiKey: String = ""
  @State private var showMainView = false

  var body: some View {
    NavigationStack {
      VStack {
        Section("OpenAI Settings") {
          TextField("API Key", text: $apiKey)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .onSubmit {
              saveApiKey()
            }
            .padding()

          Button(action: saveApiKey) {
            Text("Save")
              .padding()
              .cornerRadius(8)
          }
        }
      }
    }
    .padding()
    .onAppear {
      if ApiKeyService.getApiKey() != nil {
        showMainView = true
      }
    }
    .fullScreenCover(isPresented: $showMainView) {
      TranslatorView()
    }
  }

  func saveApiKey() {
    guard !apiKey.isEmpty else {
      return
    }
    ApiKeyService.saveApiKey(apiKey)
    showMainView = true
  }
}

#Preview {
  ApiKeyInputView()
}
