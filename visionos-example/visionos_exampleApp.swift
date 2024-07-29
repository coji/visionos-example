//
//  visionos_exampleApp.swift
//  visionos-example
//
//  Created by coji on 2024/07/21.
//

import SwiftUI

@main
struct visionos_exampleApp: App {
  @AppStorage("IsFirstLaunch") var isFirstLaunch: Bool = true
  var body: some Scene {
    WindowGroup {
      if isFirstLaunch {
        ApiKeyInputView()
          .onAppear {
            isFirstLaunch = false
          }
      } else {
        TranslatorView()
      }
    }
  }
}
