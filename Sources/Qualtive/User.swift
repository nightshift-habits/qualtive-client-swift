import Foundation

public struct User {

    public let clientId: String
    public var id: String?
    public var name: String?
    public var email: String?

    public init(id: String? = nil, name: String? = nil, email: String? = nil) {
        self.clientId = Self.clientId
        self.id = id
        self.name = name
        self.email = email
    }

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
