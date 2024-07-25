//
//  TextView.swift
//  visionos-example
//
//  Created by coji on 2024/07/25.
//

import SwiftUI

struct TextView: View {
  let text: String

  var body: some View {
    ScrollView {
      VStack {
        Text(text)
          .lineLimit(nil)
          .textSelection(.enabled)
          .font(.system(size: 48))
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .clipShape(RoundedRectangle(cornerRadius: 10))
    .background(Color.black)
  }
}

#Preview {
  NavigationStack {
    TextView(text: "hello")
  }
}
