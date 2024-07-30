//
//  SpeechRecognition.swift
//  visionos-example
//
//  Created by coji on 2024/07/25.
//

import AVFoundation
import Foundation
import Speech
import SwiftUI
import OpenAI

@Observable
class SpeechRecognition: ObservableObject {
  enum RecognizerError: Error {
    case nilRecognizer
    case notAuthorizedToRecognize
    case notPermittedToRecord
    case recognizerIsUnavailable

    var message: String {
      switch self {
      case .nilRecognizer: return "Can't initialize speech recognizer"
      case .notAuthorizedToRecognize: return "Not authorized to recognize speech"
      case .notPermittedToRecord: return "Not permitted to record audio"
      case .recognizerIsUnavailable: return "Recognizer is unavailable"
      }
    }
  }

  @MainActor var isRecording: Bool = false
  @MainActor var isOnDevice: Bool = false
  @MainActor private(set) var transcript: String = ""
  @MainActor private(set) var translated: String = ""

  private var audioEngine: AVAudioEngine?
  private var request: SFSpeechAudioBufferRecognitionRequest?
  private var task: SFSpeechRecognitionTask?
  private let recognizer: SFSpeechRecognizer?

  init() {
    recognizer = SFSpeechRecognizer()
    guard recognizer != nil else {
      transcribe(RecognizerError.nilRecognizer)
      return
    }

    Task {
      do {
        guard await SFSpeechRecognizer.hasAuthorizationToRecognize() else {
          throw RecognizerError.notAuthorizedToRecognize
        }
        guard await AVAudioSession.sharedInstance().hasPermissionToRecord() else {
          throw RecognizerError.notPermittedToRecord
        }
      } catch {
        transcribe(error)
      }
    }
  }

  @MainActor func startTranscribing() {
    isRecording = true
    Task {
      transcribe(isOnDevice: isOnDevice)
    }
  }

  @MainActor func stopTranscribing() {
    isRecording = false
    Task {
      reset()
    }
  }

  private func transcribe(isOnDevice: Bool) {
    guard let recognizer, recognizer.isAvailable else {
      transcribe(RecognizerError.recognizerIsUnavailable)
      return
    }

    do {
      let (audioEngine, request) = try Self.prepareEngine()
      self.audioEngine = audioEngine
      self.request = request
      self.request?.requiresOnDeviceRecognition = isOnDevice
      task = recognizer.recognitionTask(with: request, resultHandler: { [weak self] result, error in
        self?.recognitionHandler(audioEngine: audioEngine, result: result, error: error)
      })
    } catch {
      reset()
      transcribe(error)
    }
  }

  /// Reset the speech recognizer.
  private func reset() {
    task?.cancel()
    audioEngine?.stop()
    audioEngine = nil
    request = nil
    task = nil
  }

  private static func prepareEngine() throws -> (AVAudioEngine, SFSpeechAudioBufferRecognitionRequest) {
    let audioEngine = AVAudioEngine()

    let request = SFSpeechAudioBufferRecognitionRequest()
    request.shouldReportPartialResults = true

    let audioSession = AVAudioSession.sharedInstance()
    try audioSession.setCategory(.playAndRecord, mode: .measurement, options: .duckOthers)
    try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    let inputNode = audioEngine.inputNode

    let recordingFormat = inputNode.outputFormat(forBus: 0)
    inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, _: AVAudioTime) in
      request.append(buffer)
    }
    audioEngine.prepare()
    try audioEngine.start()

    return (audioEngine, request)
  }

  private nonisolated func recognitionHandler(audioEngine: AVAudioEngine, result: SFSpeechRecognitionResult?, error: Error?) {
    let receivedFinalResult = result?.isFinal ?? false
    let receivedError = error != nil

    if receivedFinalResult || receivedError {
      audioEngine.stop()
      audioEngine.inputNode.removeTap(onBus: 0)
    }

    if let result, !receivedFinalResult {
      let text = result.bestTranscription.formattedString
      transcribe(text)
      if text != "" {
        Task {
          await fetchOpenAIResponse(text)
        }
      }
    }
  }

  private nonisolated func transcribe(_ message: String) {
    Task { @MainActor in
      transcript = message
    }
  }

  private nonisolated func transcribe(_ error: Error) {
    var errorMessage = ""
    if let error = error as? RecognizerError {
      errorMessage += error.message
    } else {
      errorMessage += error.localizedDescription
    }
    Task { @MainActor [errorMessage] in
      transcript = "<< \(errorMessage) >>"
    }
  }

  private func fetchOpenAIResponse(_ text: String) async {
    let openAI = OpenAI(apiToken: ApiKeyService.getApiKey() ?? "")
    guard let message = ChatQuery.ChatCompletionMessageParam(role: .user, content: "あなたは優秀な翻訳者です。以下の英文を日本語に翻訳してください。翻訳文だけでokです。\n\n\(text)") else { return }
    let query = ChatQuery(messages: [message], model: .gpt4_o_mini)

    do {
      let result = try await openAI.chats(query: query)
      if let firstChoice = result.choices.first {
        switch firstChoice.message {
        case .assistant(let assistantMessage):
          Task { @MainActor [assistantMessage] in
            translated = assistantMessage.content ?? "No response"
            log(translated)
          }
        default:
          break
        }
      }
    } catch {
      await MainActor.run {
        translated = "エラー: \(error.localizedDescription)"
      }
    }
  }

  func log(_ message: String) {
      let dateFormatter = DateFormatter()
      dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
      let dateString = dateFormatter.string(from: Date())
      print("[\(dateString)] \(message)")
  }
}

extension SFSpeechRecognizer {
  static func hasAuthorizationToRecognize() async -> Bool {
    await withCheckedContinuation { continuation in
      requestAuthorization { status in
        continuation.resume(returning: status == .authorized)
      }
    }
  }
}

extension AVAudioSession {
  func hasPermissionToRecord() async -> Bool {
    await withCheckedContinuation { continuation in
      AVAudioApplication.requestRecordPermission { authorized in
        continuation.resume(returning: authorized)
      }
    }
  }
}
