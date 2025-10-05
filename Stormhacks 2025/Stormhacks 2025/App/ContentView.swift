import SwiftUI

let api = APIClient(
  serverBase: "https://sfu-place-web-server.vercel.app",
  firebaseApiKey: "<FIREBASE_WEB_API_KEY>"
)

struct ContentView: View {
  @State private var showAR = false
  @State private var surfaceUid: String = ""
  @State private var log: String = ""

  var body: some View {
    NavigationStack {
      VStack(spacing: 16) {
        Text("SFU Place")
          .font(.largeTitle.bold())

        Button("Open AR Canvas") { showAR = true }
          .buttonStyle(.borderedProminent)

        Divider().padding(.vertical, 4)

        Button("Sign In") {
          Task {
            do {
              _ = try await api.signIn(email: "<email>", password: "<password>")
              log = "Signed in as \(api.userId ?? "?")"
            } catch { log = "SignIn error: \(error.localizedDescription)" }
          }
        }

        Button("Create Surface") {
          Task {
            do {
              let s = SurfacePayload(
                surface_local_id: "arkit-plane-\(Int.random(in: 1000...9999))",
                center: .init(x: 30, y: 50, z: 60),
                extent: .init(x: 50, y: 20),
                normal: .init(x: 10, y: 20, z: 40),
                users: nil
              )
              surfaceUid = try await api.createSurface(s)
              log = "Surface uid = \(surfaceUid)"
            } catch { log = "Create error: \(error.localizedDescription)" }
          }
        }

        Button("Send 1-point stroke (Blue)") {
          Task {
            guard !surfaceUid.isEmpty else { log = "Create surface first"; return }
            do {
              try await api.postPointStroke(surfaceUid: surfaceUid, color: "Blue", x: 30, y: 50, z: 50)
              log = "Sent 1-point stroke"
            } catch { log = "Stroke error: \(error.localizedDescription)" }
          }
        }

        Button("Send polyline stroke (#FF3355)") {
          Task {
            guard !surfaceUid.isEmpty else { log = "Create surface first"; return }
            do {
              let pts = (0..<12).map { i in V3(x: Double(i) * 0.02, y: 1.0, z: -1.0) }
              try await api.postPolylineStroke(surfaceUid: surfaceUid, colorHex: "#FF3355", points: pts, size: 0.015)
              log = "Sent polyline stroke"
            } catch { log = "Polyline error: \(error.localizedDescription)" }
          }
        }

        ScrollView {
          Text(log)
            .font(.footnote)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxHeight: 140)
      }
      .padding()
      .sheet(isPresented: $showAR) {
        // Unity behind; SwiftUI overlay on top (transparent)
        ARScreen()
      }
      .navigationTitle("Home")
    }
  }
}

