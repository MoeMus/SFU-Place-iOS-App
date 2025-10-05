import Foundation
import UIKit

#if canImport(UnityFramework)
import UnityFramework

final class UnityManager: NSObject, UnityFrameworkListener {
  static let shared = UnityManager()
  private var ufw: UnityFramework?
  private var isRunning = false

    
    func showUnity() {
      DispatchQueue.main.async {
        self.loadUnityIfNeeded()
        guard let ufw = self.ufw else { return }
        if self.isRunning { ufw.showUnityWindow(); return }

        // --- Provide a non-null argv with at least one C-string ---
        // You can add real flags here if you want (e.g., "-force-gfx-metal")
        let args: [String] = ["UnityApp"]
        var cArgs: [UnsafeMutablePointer<Int8>?] = args.map { strdup($0) }
        // (Unity’s native code iterates argv; some builds don’t require a NULL terminator, but it’s safe.)
        cArgs.append(nil)

        cArgs.withUnsafeMutableBufferPointer { buf in
          var argc: Int32 = Int32(args.count)
          ufw.runEmbedded(withArgc: argc, argv: buf.baseAddress, appLaunchOpts: nil)
        }

        // Clean up the duplicated C strings
        for p in cArgs where p != nil { free(p) }

        self.isRunning = true
      }
    }



  func unloadUnity() { ufw?.unloadApplication() }

  // Unity root VC, made transparent for SwiftUI overlay
  func viewController() -> UIViewController? {
    guard let vc = ufw?.appController()?.rootViewController else { return nil }
    vc.view.isOpaque = false
    vc.view.backgroundColor = .clear
    return vc
  }

  // Send message into Unity
  func send(go name: String, method: String, message: String) {
    ufw?.sendMessageToGO(withName: name, functionName: method, message: message)
  }

  // MARK: - UnityFramework wiring
    private func loadUnityIfNeeded() {
      if ufw != nil { return }
      guard let bundle = Bundle(path: Bundle.main.bundlePath + "/Frameworks/UnityFramework.framework") else { return }
      if !bundle.isLoaded { bundle.load() }
      guard let cls = bundle.principalClass as? UnityFramework.Type else { return }

      let u = cls.getInstance()
      u?.register(self)
      ufw = u
    }


  // UnityFrameworkListener
  func unityDidUnload(_ notification: Notification!) {
    isRunning = false
    ufw = nil
  }
}

#else   // ---- No UnityFramework present ----

final class UnityManager {
  static let shared = UnityManager()
  func showUnity() {}
  func unloadUnity() {}
  func viewController() -> UIViewController? {
    // returns a dummy VC so SwiftUI layout still works
    let vc = UIViewController()
    vc.view.isOpaque = false
    vc.view.backgroundColor = .clear
    return vc
  }
  func send(go name: String, method: String, message: String) {}
}
#endif

