import SwiftUI

let api = APIClient(
  serverBase: "https://sfu-place-web-server.vercel.app",
  firebaseApiKey: "AIzaSyCEzgWZn9GAlMjYiGWN_bIJZW6XO0JM960"
)

struct ContentView: View {
  @State private var showCreate = false
  @State private var showSignIn = false
  @State private var showAR = false
  @State private var surfaceUid: String = ""
  @State private var log: String = ""

  var body: some View {
    NavigationStack {
      VStack(spacing: 14) {
        Text("SFU Place").font(.largeTitle.bold())

        // Create Account → opens form, then auto-signs in
        Button("Create Account") { showCreate = true }
          .buttonStyle(.borderedProminent)

        // Sign In → opens form (email/password)
        Button("Sign In") { showSignIn = true }
          .buttonStyle(.bordered)

        Button("Create Surface & Start Sync") {
          Task {
            do {
              let surf = SurfacePayload(
                surface_local_id: "arkit-plane-\(Int.random(in: 1000...9999))",
                center: .init(x: 30, y: 50, z: 60),
                extent: .init(x: 50, y: 20),
                normal: .init(x: 10, y: 20, z: 40),
                users: nil
              )
              let uid = try await api.createSurface(surf)
              surfaceUid = uid
              log = "Surface uid: \(uid)"
            } catch { log = "Create surface error: \(error.localizedDescription)" }
          }
        }

        Button("Open AR Canvas") { showAR = true }

        ScrollView {
          Text(log).font(.footnote).frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxHeight: 140)
      }
      .padding()
      // Sheets
      .sheet(isPresented: $showCreate) {
        CreateAccountView(api: api) { email, uid in
          log = "Account created + signed in: \(email) (\(uid))"
        }
      }
      .sheet(isPresented: $showSignIn) {
        SignInView(api: api) { email, uid in
          log = "Signed in as \(email) (\(uid))"
        }
      }
      .sheet(isPresented: $showAR) { ARScreen() }
      .navigationTitle("Home")
    }
  }
}

/// Simple email/password sign-in sheet.
/// Uses APIClient.signIn and returns the signed-in email/uid on success.
struct SignInView: View {
  let api: APIClient
  var onSignedIn: (_ email: String, _ uid: String) -> Void

  @Environment(\.dismiss) private var dismiss

  @State private var email: String = UserDefaults.standard.string(forKey: "lastEmail") ?? ""
  @State private var password: String = ""
  @State private var showPassword: Bool = false
  @State private var isBusy: Bool = false
  @State private var errorText: String?

  var body: some View {
    NavigationStack {
      Form {
        Section("Sign in to continue") {
          TextField("Email", text: $email)
            .keyboardType(.emailAddress)
            .textInputAutocapitalization(.never)
            .textContentType(.username)
            .autocorrectionDisabled()

          HStack {
            Group {
              if showPassword {
                TextField("Password", text: $password)
              } else {
                SecureField("Password", text: $password)
              }
            }
            .textContentType(.password)

            Button(action: { showPassword.toggle() }) {
              Image(systemName: showPassword ? "eye.slash" : "eye")
                .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(showPassword ? "Hide password" : "Show password")
          }
        }

        if let err = errorText {
          Section { Text(err).foregroundStyle(.red).font(.footnote) }
        }

        Section {
          Button {
            Task { await doSignIn() }
          } label: {
            if isBusy { ProgressView() } else { Text("Sign In") }
          }
          .disabled(!canSubmit || isBusy)
        }
      }
      .navigationTitle("Sign In")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Close") { dismiss() }
        }
      }
    }
  }

  private var canSubmit: Bool {
    email.contains("@") && !password.isEmpty
  }

  private func doSignIn() async {
    errorText = nil
    isBusy = true
    defer { isBusy = false }

    do {
      let (_, uid) = try await api.signIn(email: email.trimmingCharacters(in: .whitespaces),
                                          password: password)
      UserDefaults.standard.set(email, forKey: "lastEmail")
      onSignedIn(email, uid)
      dismiss()
    } catch {
      let msg = error.localizedDescription
      if msg.contains("EMAIL_NOT_FOUND") { errorText = "No account found for this email." }
      else if msg.contains("INVALID_PASSWORD") { errorText = "Incorrect password." }
      else if msg.contains("TOO_MANY_ATTEMPTS_TRY_LATER") { errorText = "Too many attempts. Try again later." }
      else { errorText = "Could not sign in. \(msg)" }
    }
  }
}

