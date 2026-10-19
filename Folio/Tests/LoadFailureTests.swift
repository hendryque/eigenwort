import Foundation
import Testing
@testable import Folio

/// The error page's plain sentences depend on telling these cases apart, and
/// a load abandoned by navigation must never surface as a failure.
struct LoadFailureTests {

    @Test("Being offline is told apart from Wikipedia being slow or down")
    func offlineAndUnavailable() {
        #expect(LoadFailure(WikipediaError.mapping(URLError(.notConnectedToInternet))) == .offline)
        #expect(LoadFailure(WikipediaError.mapping(URLError(.networkConnectionLost))) == .offline)
        #expect(LoadFailure(WikipediaError.mapping(URLError(.timedOut))) == .unavailable)
        #expect(LoadFailure(WikipediaError.httpStatus(503)) == .unavailable)
        #expect(LoadFailure(WikipediaError.httpStatus(429)) == .unavailable)
    }

    @Test("A missing article is its own case, so the page can offer search")
    func notFound() {
        #expect(LoadFailure(WikipediaError.httpStatus(404)) == .notFound)
    }

    @Test("Cancellation is not a failure")
    func cancellation() {
        #expect(LoadFailure(WikipediaError.mapping(URLError(.cancelled))) == nil)
        #expect(LoadFailure(CancellationError()) == nil)
    }

    @Test("Anything else gets the general sentence")
    func other() {
        #expect(LoadFailure(WikipediaError.decoding("unexpected key")) == .other)
        #expect(LoadFailure(WikipediaError.mapping(URLError(.badServerResponse))) == .other)
        #expect(LoadFailure(URLError(.badServerResponse)) == .other)
    }
}
