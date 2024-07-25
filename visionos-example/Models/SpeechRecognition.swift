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
  @MainActor private(set) var transcript: String = ""

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
      await transcribe()
    }
  }

  @MainActor func stopTranscribing() {
    isRecording = false
    Task {
      await reset()
    }
  }

  private func transcribe() {
    guard let recognizer, recognizer.isAvailable else {
      transcribe(RecognizerError.recognizerIsUnavailable)
      return
    }

    do {
      let (audioEngine, request) = try Self.prepareEngine()
      self.audioEngine = audioEngine
      self.request = request
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

    if let result {
      transcribe(result.bestTranscription.formattedString)
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
