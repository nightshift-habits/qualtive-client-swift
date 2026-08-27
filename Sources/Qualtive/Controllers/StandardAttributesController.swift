import Foundation

#if os(iOS)
  import UIKit
#endif

/// Produces the standard device/app attributes collected when posting feedback.
protocol StandardAttributesControllerType: Sendable {

  func makeAttributes(locale: Locale) async -> Attributes
}

extension StandardAttributesControllerType {

  func makeAttributes() async -> Attributes {
    await makeAttributes(locale: .current)
  }
}

/// Collects platform, device, app, and locale attributes.
struct StandardAttributesController: StandardAttributesControllerType {

  init() {}

  func makeAttributes(locale: Locale) async -> Attributes {
    var attributes = Attributes()

    if let value = platform() { attributes[.platform] = value }

    if let value = os() { attributes[.os] = value }
    if let value = osVersion() { attributes[.osVersion] = value }

    if let value = deviceModel() { attributes[.deviceModel] = value }
    if let value = await deviceType() { attributes[.deviceType] = value }

    if let value = appIdentifier() { attributes[.appId] = value }
    if let value = appVersion() { attributes[.appVersion] = value }
    if let value = appBuild() { attributes[.appBuild] = value }

    if let value = language(locale: locale) { attributes[.language] = value }
    if let value = region(locale: locale) { attributes[.region] = value }

    return attributes
  }
}

extension StandardAttributesController {

  private func platform() -> String? {
    #if os(iOS)
      return "iOS"
    #elseif os(macOS)
      return "macOS"
    #elseif os(tvOS)
      return "tvOS"
    #elseif os(watchOS)
      return "iOS"  // Can be discussed. Often bundled with iOS app.
    #else
      return nil
    #endif
  }

  private func os() -> String? {
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

  private func osVersion() -> String? {
    let version = ProcessInfo.processInfo.operatingSystemVersion
    return "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
  }

  private func deviceModel() -> String? {
    func hwmodel() -> String? {
      var count = 0
      sysctlbyname("hw.model", nil, &count, nil, 0)
      guard count > 0 else {
        return nil
      }
      var model = [CChar](repeating: 0, count: count)
      sysctlbyname("hw.model", &model, &count, nil, 0)
      let utf8 = model.prefix { $0 != 0 }.map { UInt8(bitPattern: $0) }
      return String(decoding: utf8, as: UTF8.self)
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

  private func deviceType() async -> String? {
    #if os(iOS)
      switch await UIDevice.current.userInterfaceIdiom {
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
      case .vision:
        return "Vision"
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

  private func appIdentifier() -> String? {
    Bundle.main.bundleIdentifier
  }

  private func appVersion() -> String? {
    Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
  }

  private func appBuild() -> String? {
    Bundle.main.infoDictionary?["CFBundleVersion"] as? String
  }

  private func language(locale: Locale) -> String? {
    locale.languageCode
  }

  private func region(locale: Locale) -> String? {
    locale.regionCode
  }
}
