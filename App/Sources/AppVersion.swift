import Foundation

/// What this build calls itself.
///
/// Read back out of the bundle rather than hard-coded in Swift, so the number
/// on screen is necessarily the number that was built and signed — it cannot
/// drift from the real thing the way a hand-edited constant can.
/// `Tools/stamp_version.sh` puts it there, deriving the build number from git
/// history so it advances by itself with every commit.
enum AppVersion {

    static var marketing: String {
        value(for: "CFBundleShortVersionString")
    }

    static var build: String {
        value(for: "CFBundleVersion")
    }

    /// "1.0 (build 12)"
    static var display: String {
        "\(marketing) (build \(build))"
    }

    private static func value(for key: String) -> String {
        Bundle.main.object(forInfoDictionaryKey: key) as? String ?? "unknown"
    }
}
