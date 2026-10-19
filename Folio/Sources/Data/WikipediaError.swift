import Foundation

enum WikipediaError: LocalizedError, Sendable {
    case invalidURL
    case httpStatus(Int)
    case decoding(String)
    case transport(String)
    case offline
    case timedOut
    case empty

    /// URLSession's failures, sorted into the cases the error page tells
    /// apart. Cancellation stays cancellation, so it never shows as a failure.
    static func mapping(_ error: URLError) -> any Error {
        switch error.code {
        case .cancelled:
            CancellationError()
        case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed,
             .internationalRoamingOff, .cannotFindHost:
            WikipediaError.offline
        case .timedOut:
            WikipediaError.timedOut
        default:
            WikipediaError.transport(error.localizedDescription)
        }
    }

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            "Could not build the request URL."
        case .httpStatus(let code):
            "Wikipedia returned HTTP \(code)."
        case .decoding(let message):
            "Could not parse Wikipedia's response: \(message)"
        case .transport(let message):
            "Network error: \(message)"
        case .offline:
            "The device is offline."
        case .timedOut:
            "Wikipedia took too long to answer."
        case .empty:
            "Wikipedia returned no data."
        }
    }
}
