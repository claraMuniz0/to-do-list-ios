import Testing
@testable import MyApp

struct DSGradientTests {
    @Test func welcomeFadesFromPeachToBackgroundAt38Percent() {
        let stops = DSGradient.welcome.stops
        #expect(stops.count == 2)
        #expect(stops[0].color.lightHex == "FFE8D6")
        #expect(stops[0].location == 0)
        #expect(stops[1].color.lightHex == "FFF8F0")
        #expect(stops[1].location == 0.38)
    }
}
