import SwiftUI

struct ARScreen: View {
  var body: some View {
    ZStack {
      // Unity camera feed behind
      UnityContainer()
        .ignoresSafeArea()

      // Transparent SwiftUI overlay
      VStack {
        HStack(spacing: 12) {
          Button("Undo") {
            UnityManager.shared.send(go: "Graffiti", method: "Undo", message: "")
          }
          .buttonStyle(.bordered)

          Button("Clear") {
            UnityManager.shared.send(go: "Graffiti", method: "ClearAll", message: "")
          }
          .buttonStyle(.bordered)

          Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)

        Spacer()
      }
      .background(Color.clear)
      .allowsHitTesting(true)
    }
    .background(Color.clear)
  }
}

