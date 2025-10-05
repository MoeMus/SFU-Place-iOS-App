import SwiftUI
/*
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
          Section {
            Text(err).foregroundStyle(.red).font(.footnote)
          }
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
      // Surface server/REST errors nicely
      let msg = error.localizedDescription
      if msg.contains("EMAIL_NOT_FOUND") { errorText = "No account found for this email." }
      else if msg.contains("INVALID_PASSWORD") { errorText = "Incorrect password." }
      else if msg.contains("TOO_MANY_ATTEMPTS_TRY_LATER") { errorText = "Too many attempts. Try again later." }
      else { errorText = "Could not sign in. \(msg)" }
    }
  }
}

*/
