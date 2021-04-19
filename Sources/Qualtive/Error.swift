import Foundation

struct ParseError: Error {

    let debugMessage: String
}

enum UnexpectedError: Error {
    case remoteMaintenance
    case httpStatusCode(Int)
}

/// General network error. In most cases this occur in edge cases or when there is no internet connection.
public enum GeneralNetworkError: Error {

    /// Operation was cancelled.
    case cancelled

    /// A connection occured.
    case connection(Error)

    /// Qualtive servers are current ongoing maintenance.
    case remoteMaintenance

    /// Unexpected error occured. This should never happend.
    case unexpected(Error)
}
