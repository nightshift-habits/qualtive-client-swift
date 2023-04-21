import Foundation
#if os(iOS)
import UIKit
#endif

struct Attributes {

    private init() {}

    static func defaultAttributes(locale: Locale) -> [String: String] {
        var attributes = [String: String]()

        if let attribute = platform() { attributes["Platform"] = attribute }

        if let attribute = os() { attributes["OS"] = attribute }
        if let attribute = osVersion() { attributes["OS Version"] = attribute }

        if let attribute = deviceModel() { attributes["Device Model"] = attribute }
        if let attribute = deviceType() { attributes["Device Type"] = attribute }

        if let attribute = appIdentifier() { attributes["App ID"] = attribute }
        if let attribute = appVersion() { attributes["App Version"] = attribute }
        if let attribute = appBuild() { attributes["App Build"] = attribute }

        if let attribute = language(locale: locale) { attributes["Language"] = attribute }
        if let attribute = region(locale: locale) { attributes["Region"] = attribute }

        return attributes
    }

    private static func platform() -> String? {
        #if os(iOS)
        return "iOS"
        #elseif os(macOS)
        return "macOS"
        #elseif os(tvOS)
        return "tvOS"
        #elseif os(watchOS)
        return "iOS" // Can be discuessed. Often bundeled with iOS app.
        #else
        return nil
        #endif
    }

    private static func os() -> String? {
        #if os(iOS)
        return "iOS"
        #elseif os(macOS)
        return "macOS"
        #elseif os(tvOS)
        return "tvOS"
        #elseif os(watchOS)
        return "watchOS"
        #else
        return nil
        #endif
    }
    private static func osVersion() -> String? {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        return "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
    }

    private static func deviceModel() -> String? {

        func hwmodel() -> String? {
            var count = 0
            sysctlbyname("hw.model", nil, &count, nil, 0)
            guard count > 0 else {
                return nil
            }
            var model = [CChar](repeating: 0, count: count)
            sysctlbyname("hw.model", &model, &count, nil, 0)
            return String(cString: model)
        }

        func systemInfo() -> String? {
            var systemInfo = utsname()
            uname(&systemInfo)
            let machineMirror = Mirror(reflecting: systemInfo.machine)
            let identifier = machineMirror.children.reduce("") { identifier, element in
                guard let value = element.value as? Int8, value != 0 else { return identifier }
                return identifier + String(UnicodeScalar(UInt8(value)))
            }
            return identifier
        }

        #if os(macOS)
        return hwmodel()
        #else
        if let model = hwmodel(), model.lowercased().contains("mac") {
            return model
        }
        return systemInfo()
        #endif
    }
    private static func deviceType() -> String? {
        #if os(iOS)
        switch UIDevice.current.userInterfaceIdiom {
        case .phone:
            return "Phone"
        case .pad:
            return "Tablet"
        case .mac:
            return "Computer"
        case .tv:
            return "TV"
        case .carPlay:
            return "Car"
        case .unspecified:
            return nil
        @unknown default:
            return nil
        }
        #elseif os(macOS)
        return "Computer"
        #elseif os(tvOS)
        return "TV"
        #elseif os(watchOS)
        return "Watch"
        #else
        return nil
        #endif
    }

    private static func appIdentifier() -> String? {
        Bundle.main.bundleIdentifier
    }
    private static func appVersion() -> String? {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    }
    private static func appBuild() -> String? {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String
    }

    private static func language(locale: Locale) -> String? {
        locale.languageCode
    }
    private static func region(locale: Locale) -> String? {
        locale.regionCode
    }
}
