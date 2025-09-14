//
//  Animation.swift
//  PatrikTheStarByAria
//
//  Created by Aria Zare on 12/09/2025.
//

//This should be refactored to other files
import Foundation

struct KeyFrame {
    var time: Float = 0
    var translation: float3 = [0, 0, 0]
    //TODO: Change rotation to quaternion
    var rotation: float3 = [0, 0, 0]
//    var rotation: simd_quatf = simd_quatf()
    var scale: float3 = [0, 0, 0]
    var transformation: float4x4 {
        float4x4(translation: translation) * float4x4(rotation: rotation) * float4x4(scaling: scale)
    }
}

struct AnimationWithKeyFrames {
    var keyFrames: [KeyFrame]
    var repeatAnimation: Bool = false
    
    func getAnimation(at inputTime: Float) -> float3? {
        guard let lastKeyFrame = keyFrames.last else {
            print("Last key frame was nil")
            return nil
        }
        
        var time = inputTime
        if let firstKeyFrame = keyFrames.first,
            time <= firstKeyFrame.time {
            return firstKeyFrame.translation
        }
        
        if time >= lastKeyFrame.time,
           !repeatAnimation {
            return lastKeyFrame.translation
        }
        
        time = fmod(time, lastKeyFrame.time)
        let keyFramePairs = keyFrames.indices.dropFirst().map {
            (previous: keyFrames[$0 - 1], next: keyFrames[$0])
        }
        
        guard let (previousKey, nextKey) = keyFramePairs.first(where: {
            time < $0.next.time
        }) else {
            print("couldn't find any appropriate key paird")
            return nil
        }
        
        let interpolant = (time - previousKey.time) / (nextKey.time - previousKey.time)
        
        return simd_mix(previousKey.translation,
                        nextKey.translation,
                        float3(repeating: interpolant))
    }
}


func generateTranslations() -> AnimationWithKeyFrames {
    let keyFrames = [
        KeyFrame(time: 0,    translation: [-1, 0, 0]),
        KeyFrame(time: 0.17, translation: [ 0, 1, 0]),
        KeyFrame(time: 0.35, translation: [ 1, 0, 0]),
        KeyFrame(time: 1.0,  translation: [ 1, 0, 0]),
        KeyFrame(time: 1.17, translation: [ 0, 1, 0]),
        KeyFrame(time: 1.35, translation: [-1, 0, 0]),
        KeyFrame(time: 2,    translation: [-1, 0, 0])
    ]
    return AnimationWithKeyFrames(keyFrames: keyFrames)
}
