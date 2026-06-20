import Foundation

enum SpriteName: String, CaseIterable, Codable {
    case boardTile
    case magnetCore
    case chargedBlock
    case targetSocket
    case barrierPlate
    case hazardVent
    case emitterLens
}

enum ParticlePreset: String, CaseIterable, Codable {
    case fieldCharge
    case magneticArc
    case targetLock
    case solvedCascade
    case hazardSpark
}

enum HapticEvent: String, CaseIterable, Codable {
    case magnetPickup
    case magnetDrop
    case pulseCharge
    case blockImpact
    case targetLock
    case puzzleSolved
    case invalidMove
}

enum SoundCue: String, CaseIterable, Codable {
    case magnetHum
    case pulseRelease
    case glassSlide
    case targetChime
    case labAlarm
    case solveBloom
}

enum AnimationClip: String, CaseIterable, Codable {
    case fieldChargeUp
    case blockAcceleration
    case blockSnap
    case targetLock
    case solvedCascade
    case cameraShake
}

struct AssetManifest: Codable, Equatable {
    var sprites: [SpriteName]
    var particles: [ParticlePreset]
    var haptics: [HapticEvent]
    var sounds: [SoundCue]
    var animationClips: [AnimationClip]
    var usesProceduralPlaceholders: Bool

    static let proceduralSlice = AssetManifest(
        sprites: SpriteName.allCases,
        particles: ParticlePreset.allCases,
        haptics: HapticEvent.allCases,
        sounds: SoundCue.allCases,
        animationClips: AnimationClip.allCases,
        usesProceduralPlaceholders: true
    )
}
