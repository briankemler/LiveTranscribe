import Testing
import SwiftUI
@testable import LiveTranscribe

@Suite("Smoke")
struct SmokeTests {

    @Test("All routes have a section + label")
    func routesHaveLabels() {
        for route in Route.allCases {
            #expect(!route.section.isEmpty)
            #expect(!route.label.isEmpty)
        }
    }

    @Test("Showcase covers exactly the 16 export-deck frames")
    func showcaseFrameCount() {
        #expect(Route.showcaseFrames.count == 16)
    }

    @Test("All three palettes resolve")
    func palettesResolve() {
        for id in PaletteID.allCases {
            #expect(id.theme.isLight == (id == .paper))
        }
    }

    @Test("Speaker lookup falls back gracefully")
    func speakerLookup() {
        #expect(Speaker.find("Maya").id == "Maya")
        let unknown = Speaker.find("ZZ")
        #expect(unknown.id == "ZZ")
        #expect(unknown.initial == "Z")
    }

    @Test("Sample scripts have content")
    func scriptsExist() {
        #expect(!SampleScripts.oneToOne.isEmpty)
        #expect(!SampleScripts.group.isEmpty)
    }
}
