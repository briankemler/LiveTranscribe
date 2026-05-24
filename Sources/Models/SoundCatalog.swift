import Foundation

/// One user-facing recognized sound. Build-16: a single chip can now map to *multiple*
/// classifier IDs — useful for combined chips like "Emergency sirens" that should fire on
/// any of fire / police / ambulance siren. For most chips `classifierIDs.count == 1`.
struct UrgentSound: Hashable, Identifiable, Sendable {
    /// Stable identifier for the chip itself. Distinct from `classifierIDs` because a chip
    /// may bundle multiple Apple classifier labels (e.g. sirens). For single-ID chips this
    /// equals `classifierIDs[0]` and so the persisted `Tweaks.armedSounds` set still works.
    let chipID: String
    /// One or more Apple `version1` classifier identifiers. Detection on any of these
    /// fires this chip's UI (alert or margin tag).
    let classifierIDs: [String]
    /// SF Symbol shown on the chip + alert/margin-tag icon.
    let icon: String
    /// User-facing label.
    let label: String

    var id: String { chipID }
    /// Convenience for code that historically reached for a single classifier ID. Returns
    /// the first ID — fine for display purposes where any ID maps to the same chip.
    var classifierID: String { classifierIDs.first ?? chipID }

    /// Multi-ID factory. The first ID becomes the `chipID` for back-compat with persisted
    /// `armedSounds` sets that only ever stored single IDs.
    static func multi(ids: [String], icon: String, label: String) -> UrgentSound {
        UrgentSound(chipID: ids[0], classifierIDs: ids, icon: icon, label: label)
    }

    /// Single-ID factory — the common case.
    static func single(_ id: String, icon: String, label: String) -> UrgentSound {
        UrgentSound(chipID: id, classifierIDs: [id], icon: icon, label: label)
    }
}

/// Detection category — routes incoming classifier hits to the right UI surface.
/// `.urgent` → fires the full-bleed `AlertView`.
/// `.nonUrgent` → updates the captions-screen `SoundMarginTag` without interrupting.
enum SoundCategory: Hashable, Sendable {
    case urgent, nonUrgent
}

/// Build-16: ambient is auto-armed system-wide; the user only selects urgent chips, up to
/// `maxUrgent`. The non-urgent catalog below is curated (~30 sounds across 6 sub-categories);
/// the recognizer arms every classifier ID in that list whenever `tweaks.showAmbientSounds`
/// is on. Sub-category structure is for display only.
enum SoundCatalog {
    /// Maximum number of urgent chips the user can have armed at once. Soft cap — UI greys
    /// out further selections when this many are already on.
    static let maxUrgent: Int = 6

    static let urgent: [UrgentSound] = [
        .single("smoke_detector_smoke_alarm",        icon: "bell.fill",                       label: "Smoke alarm"),
        .single("carbon_monoxide_detector",          icon: "bell.badge.fill",                 label: "Carbon monoxide"),
        .single("baby_crying",                       icon: "figure.and.child.holdinghands",   label: "Baby crying"),
        .single("doorbell_buzz",                     icon: "bell.and.waves.left.and.right",   label: "Doorbell"),
        .single("telephone_bell_ringing",            icon: "phone.fill",                      label: "Phone ringing"),
        // Build-16 addition: one chip → three classifier IDs (fire/police/ambulance). The
        // user only sees / picks "Emergency sirens"; detection fires on any of the three.
        .multi(
            ids: ["fire_engine_siren_horn", "police_siren", "ambulance_siren"],
            icon: "car.fill",
            label: "Emergency sirens"
        ),
    ]

    /// Default armed set on first launch: the 5 original urgent IDs. The Emergency sirens
    /// chip is off by default — the user can opt into it within the 6-cap.
    static let defaultArmedIDs: Set<String> = Set(urgent.prefix(5).flatMap(\.classifierIDs))

    // MARK: - Non-urgent (always armed when `showAmbientSounds` is on)

    /// Categorized non-urgent catalog. Section labels drive the read-only display in
    /// `SoundSettingsView`. The recognizer doesn't care about sub-categories — it arms
    /// every ID below the moment captions go live.
    struct Section: Identifiable, Hashable {
        let title: String
        let sounds: [UrgentSound]
        var id: String { title }
    }

    static let nonUrgentSections: [Section] = [
        Section(title: "Pets", sounds: [
            .single("dog",  icon: "pawprint.fill", label: "Dog barking"),
            .single("cat",  icon: "pawprint",      label: "Cat"),
            .single("bird", icon: "bird.fill",     label: "Bird"),
        ]),
        Section(title: "Home", sounds: [
            .single("dishes_pots_and_pans", icon: "fork.knife",       label: "Dishes"),
            .single("vacuum_cleaner",       icon: "wind",             label: "Vacuum"),
            .single("microwave_oven",       icon: "oven",             label: "Microwave"),
            .single("blender",              icon: "tornado",          label: "Blender"),
            .single("toilet_flush",         icon: "drop.fill",        label: "Toilet flush"),
            .single("hair_dryer",           icon: "wind",             label: "Hair dryer"),
            .single("sink_filling_with_liquid", icon: "drop",         label: "Running water"),
        ]),
        Section(title: "Outdoors", sounds: [
            .single("walk_footsteps", icon: "figure.walk", label: "Footsteps"),
            .single("vehicle",        icon: "car",         label: "Vehicle"),
            .single("car_horn",       icon: "car.fill",    label: "Car horn"),
            .single("motorcycle",     icon: "scooter",     label: "Motorcycle"),
        ]),
        Section(title: "Weather", sounds: [
            .single("wind",         icon: "wind",       label: "Wind"),
            .single("rain",         icon: "cloud.rain", label: "Rain"),
            .single("thunderstorm", icon: "cloud.bolt", label: "Thunderstorm"),
            .single("ocean",        icon: "water.waves", label: "Ocean"),
        ]),
        Section(title: "Music", sounds: [
            .single("music",             icon: "music.note",       label: "Music"),
            .single("choir",             icon: "music.mic",        label: "Choir"),
            .single("drum_kit_drumming", icon: "music.quarternote.3", label: "Drums"),
            .single("acoustic_guitar",   icon: "guitars",          label: "Guitar"),
            .single("piano",             icon: "pianokeys",        label: "Piano"),
        ]),
        Section(title: "Human", sounds: [
            .single("laughter",  icon: "speaker.wave.2.fill", label: "Laughter"),
            .single("applause",  icon: "hands.clap.fill",     label: "Applause"),
            .single("crowd",     icon: "speaker.wave.3.fill", label: "Crowd"),
            .single("whistling", icon: "music.mic",           label: "Whistling"),
            .single("cough",     icon: "lungs.fill",          label: "Cough"),
            .single("sneeze",    icon: "wind",                label: "Sneeze"),
            .single("snoring",   icon: "bed.double.fill",     label: "Snoring"),
        ]),
    ]

    /// Flattened list of every non-urgent chip — used for lookups + the auto-armed set.
    static let nonUrgent: [UrgentSound] = nonUrgentSections.flatMap(\.sounds)

    /// Every classifier ID across the non-urgent catalog. `SoundRecognitionService` arms
    /// this whole set automatically — the user doesn't pick individual ambient sounds.
    static let allNonUrgentIDs: Set<String> = Set(nonUrgent.flatMap(\.classifierIDs))

    // MARK: - Lookups

    /// O(1) lookup from any classifier ID → owning chip metadata. Covers urgent + non-urgent.
    /// One classifier ID maps to at most one chip; a multi-ID chip has its label/icon
    /// returned for every ID it owns.
    static let byID: [String: UrgentSound] = {
        var d: [String: UrgentSound] = [:]
        for chip in urgent + nonUrgent {
            for id in chip.classifierIDs {
                d[id] = chip
            }
        }
        return d
    }()

    /// Routing table — which UI surface does a hit on this classifier ID drive?
    static let categoryByID: [String: SoundCategory] = {
        var d: [String: SoundCategory] = [:]
        for chip in urgent { for id in chip.classifierIDs { d[id] = .urgent } }
        for chip in nonUrgent { for id in chip.classifierIDs { d[id] = .nonUrgent } }
        return d
    }()

    /// Is *any* of this chip's classifier IDs in the given armed set? Used by the urgent
    /// picker to determine if a (potentially multi-ID) chip is "on" right now.
    static func isArmed(_ chip: UrgentSound, in armed: Set<String>) -> Bool {
        chip.classifierIDs.contains(where: armed.contains)
    }
}

/// One detected sound event. Used by both `Route.alert(...)` (urgent path) and the captions
/// margin-tag observation (non-urgent path).
struct SoundDetection: Hashable, Sendable {
    let sound: UrgentSound
    /// 0...1 confidence from the classifier at the moment of detection.
    let confidence: Float
    /// Wall-clock detection time.
    let detectedAt: Date

    /// Showcase / preview placeholder.
    static let preview = SoundDetection(
        sound: SoundCatalog.urgent[0],
        confidence: 0.96,
        detectedAt: Date()
    )
}
