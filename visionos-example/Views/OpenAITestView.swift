//
//  OpenAITestView.swift
//  visionos-example
//
//  Created by coji on 2024/07/29.
//

import OpenAI
import SwiftUI

struct OpenAITestView: View {
  @State private var responseText: String = ""
  @State private var isLoading: Bool = false

  var body: some View {
    NavigationStack {
      VStack {
        Text(responseText)
          .padding()


        Button("Test", action: {
          Task {
            await fetchOpenAIResponse()
          }
        })

        if isLoading {
          Text("Loading...")
        }
      }
    }.task {
      await fetchOpenAIResponse()
    }
  }

  @MainActor
  func fetchOpenAIResponse() async {
    isLoading = true
    let openAI = OpenAI(apiToken: ApiKeyService.getApiKey() ?? "")
    guard let message = ChatQuery.ChatCompletionMessageParam(role: .user, content: "あなたは熟練の翻訳家です。以下のテキストを元に日本語の創作物語をつくってください\n\nHello, guys!") else { return }
    let query = ChatQuery(messages: [message], model: .gpt4_o_mini)

    do {
      let result = try await openAI.chats(query: query)
      if let firstChoice = result.choices.first {
        switch firstChoice.message {
        case .assistant(let assistantMessage):
          await MainActor.run {
            responseText = assistantMessage.content ?? "No response"
          }
        default:
          break
        }
      }
    } catch {
      await MainActor.run {
        responseText = "エラー: \(error.localizedDescription)"
      }
    }
    isLoading = false
  }
}

#Preview {
  OpenAITestView()
}
