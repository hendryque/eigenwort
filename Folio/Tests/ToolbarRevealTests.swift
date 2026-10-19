import Testing
@testable import Folio

/// The bar used to come back 0.8 s after every scroll, which is to say during
/// every reading pause. These pin the rules that replaced the timer.
struct ToolbarRevealTests {

    private func reader(at y: Double, remaining: Double = 5_000) -> ToolbarReveal {
        var reveal = ToolbarReveal()
        reveal.update(y: y, remaining: remaining)
        return reveal
    }

    @Test("Opening an article mid-way shows the bar: arriving is not scrolling")
    func arrivalShows() {
        #expect(reader(at: 2_400).isVisible)
    }

    @Test("Reading down hides it, and pausing does not bring it back")
    func readingDownHides() {
        var reveal = reader(at: 1_000)
        reveal.update(y: 1_040, remaining: 4_960)
        #expect(!reveal.isVisible)
        reveal.update(y: 1_040, remaining: 4_960)
        reveal.update(y: 1_040, remaining: 4_960)
        #expect(!reveal.isVisible)
    }

    @Test("A small upward settle is not a request for the bar")
    func smallUpwardStaysHidden() {
        var reveal = reader(at: 1_000)
        reveal.update(y: 1_100, remaining: 4_900)
        reveal.update(y: 1_088, remaining: 4_912)
        #expect(!reveal.isVisible)
    }

    @Test("A deliberate scroll up brings it back, even across several reports")
    func deliberateUpwardShows() {
        var reveal = reader(at: 1_000)
        reveal.update(y: 1_100, remaining: 4_900)
        reveal.update(y: 1_088, remaining: 4_912)
        reveal.update(y: 1_070, remaining: 4_930)
        #expect(reveal.isVisible)
    }

    @Test("Scrolling down again after summoning it hides it again")
    func downAfterUpHides() {
        var reveal = reader(at: 1_000)
        reveal.update(y: 1_100, remaining: 4_900)
        reveal.update(y: 1_050, remaining: 4_950)
        #expect(reveal.isVisible)
        reveal.update(y: 1_060, remaining: 4_940)
        #expect(!reveal.isVisible)
    }

    @Test("It always shows at the top and at the end of the article")
    func edgesShow() {
        var reveal = reader(at: 1_000)
        reveal.update(y: 1_100, remaining: 4_900)
        #expect(!reveal.isVisible)
        reveal.update(y: 6_000, remaining: ToolbarReveal.edge - 1)
        #expect(reveal.isVisible)

        var top = reader(at: 1_000)
        top.update(y: 1_100, remaining: 4_900)
        top.update(y: ToolbarReveal.edge - 1, remaining: 6_000)
        #expect(top.isVisible)
    }
}
