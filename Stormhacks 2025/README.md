# SFU Place — iOS App

SwiftUI app that:

* Authenticates with **Firebase** to obtain an ID token
* Talks to the backend at **[https://sfu-place-web-server.vercel.app](https://sfu-place-web-server.vercel.app)**
* (TODO) Embeds a **Unity** AR scene with a transparent SwiftUI overlay

---

## Prerequisites

* **macOS** with **Xcode 15+**
* **iPhone** (iOS 16+), a USB cable, and **Developer Mode** enabled
  *Settings → Privacy & Security → Developer Mode → On*
* An **Apple ID** added in Xcode (for free “Personal Team” signing)
* Access to the **same Firebase project** used by the server:

  * **Web API Key**
  * A test **email/password** account

---

## App Configuration Instructions

1. **Server + Firebase keys**
   In `ContentView.swift` (or `APIClient` init), set:

   ```swift
   let api = APIClient(
     serverBase: "https://sfu-place-web-server.vercel.app",
     firebaseApiKey: "<FIREBASE_WEB_API_KEY>"
   )
   ```

   Replace `"<FIREBASE_WEB_API_KEY>"` and use valid test credentials when tapping **Sign In**.

2. **Camera permission (Info.plist)**
   Add **Privacy – Camera Usage Description**:
   `Used for AR camera feed.`

3. **Signing**

   * Target **Stormhacks 2025 → Signing & Capabilities**:

     * ✔ Automatically manage signing
     * Team: *Your Personal Team*
     * Set a unique **Bundle Identifier** (e.g., `com.yourname.stormhacks2025`)

---

## Run on Device

1. Plug in your iPhone → **Trust** computer → ensure **Developer Mode** is ON.
2. In Xcode:

   * Scheme: **Stormhacks 2025**
   * Destination: **Your iPhone**
3. **Run** (▶).
4. In the app:

   * **Sign In** → **Create Surface** → **Send stroke** (see logs in Xcode console).
   * **Open AR Canvas** (if you wired the AR screen) to see the Unity camera background with SwiftUI controls on top.

> The server is HTTPS; no ATS exceptions required.
