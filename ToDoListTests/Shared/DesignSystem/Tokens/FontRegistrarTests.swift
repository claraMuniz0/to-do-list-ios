import Testing
import UIKit
@testable import MyApp

struct FontRegistrarTests {
    @Test func bundlesTheSevenFontFiles() {
        #expect(FontRegistrar.fontFileNames.count == 7)
        for name in FontRegistrar.fontFileNames {
            #expect(Bundle.main.url(forResource: name, withExtension: "ttf") != nil, "\(name).ttf missing from bundle")
        }
    }

    @Test func registersEveryFileWithoutFailures() {
        #expect(FontRegistrar.registerAll().isEmpty)
    }

    @Test(arguments: ["Fraunces", "Bricolage Grotesque", "Outfit", "Caveat", "DM Mono"])
    func familyIsAvailableAfterRegistration(family: String) {
        _ = FontRegistrar.registerAll()
        #expect(UIFont.familyNames.contains(family), "\(family) not registered")
    }

    @Test func registeringTwiceIsNotAFailure() {
        _ = FontRegistrar.registerAll()
        #expect(FontRegistrar.registerAll().isEmpty)
    }

    @Test func everyDSFontFamilyIsAvailable() {
        _ = FontRegistrar.registerAll()
        for font in DSFont.allCases {
            #expect(UIFont(name: font.spec.family, size: 12) != nil, "\(font.spec.family)")
        }
    }
}
