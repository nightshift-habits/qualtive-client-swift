import Foundation

struct ParseError: Error {

    let debugMessage: String
}

enum UnexpectedError: Error {
    case remoteMaintenance
    case httpStatusCode(Int)
}
