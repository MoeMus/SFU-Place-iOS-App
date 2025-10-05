import SwiftUI

struct CreateAccountView: View {
  let api: APIClient
  var onComplete: (_ email: String, _ uid: String) -> Void

  @Environment(\.dismiss) private var dismiss

  @State private var name = ""
  @State private var email = ""
  @State private var password = ""
  @State private var isBusy = false
  @State private var errorText: String?

  var body: some View {
    NavigationStack {
      Form {
        Section("Your Info") {
          TextField("Name", text: $name)
            .textContentType(.name)
            .autocorrectionDisabled()

          TextField("Email", text: $email)
            .textInputAutocapitalization(.never)
            .keyboardType(.emailAddress)
            .textContentType(.emailAddress)

          SecureField("Password (min 3 chars)", text: $password)
            .textContentType(.newPassword)
        }

        if let err = errorText {
          Section {
            Text(err).foregroundStyle(.red).font(.footnote)
          }
        }

        Section {
          Button {
            Task { await createAccount() }
          } label: {
            if isBusy { ProgressView() } else { Text("Create Account") }
          }
          .disabled(!canSubmit || isBusy)
        }
      }
      .navigationTitle("Create Account")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Close") { dismiss() }
        }
      }
    }
  }

  private var canSubmit: Bool {
    !name.trimmingCharacters(in: .whitespaces).isEmpty &&
    email.contains("@") &&
    password.count >= 3
  }

  private func createAccount() async {
    errorText = nil
    isBusy = true
    defer { isBusy = false }

    do {
      let (_, uid) = try await api.registerAndSignIn(name: name, email: email, password: password)
      onComplete(email, uid)
      dismiss()
    } catch {
      errorText = friendly(error)
    }
  }

  private func friendly(_ error: Error) -> String {
    let msg = error.localizedDescription
    if msg.contains("EMAIL_EXISTS") { return "Email already in use." }
    if msg.contains("WEAK_PASSWORD") { return "Password must be at least 6 characters." }
    return "Could not create account. \(msg)"
  }
}

