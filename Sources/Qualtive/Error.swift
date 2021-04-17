import Foundation

struct ParseError: Error {

    let debugMessage: String
}

enum UnexpectedError: Error {
    case remoteMaintenance
    case httpStatusCode(Int)
}

public enum GeneralNetworkError: Error {
    case cancelled
    case connection(Error)
    case unexpected(Error)
    case remoteMaintenance
}
