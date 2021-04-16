import Foundation
import os

@available(iOS 10.0, *)
extension OSLog {

    static let qualtive = OSLog(subsystem: Bundle.main.bundleIdentifier ?? "", category: "qualtive")
}

func logHintNewVersion() {
    let text: StaticString = "There may be a new version of the Qualtive Client Library - Swift. Please update to get the latest features and fixes."
    if #available(iOS 10.0, *) {
        os_log(text, log: .qualtive)
    } else {
        NSLog("Qualtive: " + String(describing: text))
    }
}
