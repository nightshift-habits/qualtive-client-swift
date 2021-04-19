import Foundation

public struct User {

    /// Uniq client id for this device.
    public let clientId: String

    /// Your company defined user id.
    public var id: String?

    /// Name or alias for the user.
    public var name: String?

    /// Reachable email for the user.
    public var email: String?

    /// Initialize a user with defined properties.
    /// - Parameters:
    ///   - id: Your company defined user id.
    ///   - name: Name or alias for the user.
    ///   - email: Reachable email for the user.
    public init(id: String? = nil, name: String? = nil, email: String? = nil) {
        self.clientId = Self.clientId
        self.id = id
        self.name = name
        self.email = email
    }

    /// Uniq client id for this device.
    public static let clientId: String = {
        let key = "_qualtiveCID"
        if let existing = UserDefaults.standard.object(forKey: key) as? String {
            return existing
        }
        let id = UUID().uuidString
        UserDefaults.standard.set(id, forKey: key)
        return id
    }()
}
