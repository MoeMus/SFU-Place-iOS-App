import Foundation
import UIKit

#if canImport(UnityFramework)
import UnityFramework

final class UnityManager: NSObject, UnityFrameworkListener {
  static let shared = UnityManager()
  private var ufw: UnityFramework?
  private var isRunning = false

  // Show Unity
  func showUnity() {
    loadUnityIfNeeded()
    guard let ufw else { return }
    if isRunning { ufw.showUnityWindow(); return }
    var argc: Int32 = 0
    ufw.runEmbedded(withArgc: &argc, argv: nil, appLaunchOpts: nil)
    isRunning = true
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
    if u?.appController() == nil { var header = _mh_execute_header; u?.setExecuteHeader(&header) }
    u?.register(self)
    ufw = u
  }

  // UnityFrameworkListener
  func unityDidUnload(_ notification: Notification!) {
    isRunning = false
    ufw = nil
  }
}

#else   // ---- No UnityFramework present stub ----

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

