import SwiftUI
import UIKit

/// Thin wrapper around `UIActivityViewController` so SwiftUI views can present the system
/// share sheet via `.sheet`. SwiftUI's `ShareLink` works for a single tap target, but for
/// flows that need the share sheet driven by `@State` (e.g. swipe-actions, toolbar buttons
/// that toggle into share mode) the `UIActivityViewController` route is more flexible.
///
/// The system sheet automatically surfaces every app the user has installed that accepts
/// the activity items — Notes, Files, Mail, Messages, Google Drive (if installed), etc.
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    var subject: String? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let vc = UIActivityViewController(activityItems: items, applicationActivities: nil)
        if let subject {
            vc.setValue(subject, forKey: "subject")  // pre-fills Mail subject line
        }
        return vc
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
