import SwiftUI
import UIKit

struct UnityContainer: UIViewControllerRepresentable {
  func makeUIViewController(context: Context) -> UIViewController {
    UnityManager.shared.showUnity()
    // Uses Unity VC if available, otherwise a transparent placeholder
    return UnityManager.shared.viewController() ?? {
      let vc = UIViewController()
      vc.view.isOpaque = false
      vc.view.backgroundColor = .clear
      return vc
    }()
  }

  func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

