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
      Text(text)
        .lineLimit(nil)
        .textSelection(.enabled)
        .font(.system(size: 48))
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .background(Color.black)
  }
}

#Preview {
  NavigationStack {
    TextView(text: "hello")
  }
}
