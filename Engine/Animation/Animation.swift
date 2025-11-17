//
//  Animation.swift
//  PatrikTheStarByAria
//
//  Created by Aria Zare on 12/09/2025.
//

//This should be refactored to other files
import Foundation
import ModelIO

struct TranslationKeyFrame {
    var time: Float = 0
    var translation: float3 = [0, 0, 0]
}

struct RotationKeyFrame {
    var time: Float = 0
    var rotationQuatf: simd_quatf = simd_quatf()
}

struct ScaleKeyFrame {
    var time: Float = 0
    var scale: float3 = [0, 0, 0]
}

struct AnimationWithKeyFrames {
    var translationKeyFrames: [TranslationKeyFrame] = []
    var rotationKeyFrames: [RotationKeyFrame] = []
    var scaleKeyFrames: [ScaleKeyFrame] = []

    var repeatAnimation: Bool = true
    
    func getTranslation(at inputTime: Float) -> float3? {
        guard let lastKeyFrame = translationKeyFrames.last else {
            print("Last translation key frame was nil")
            return nil
        }
        
        var time = inputTime
        if let firstKeyFrame = translationKeyFrames.first,
            time <= firstKeyFrame.time {
            return firstKeyFrame.translation
        }
        
        if time >= lastKeyFrame.time,
           !repeatAnimation {
            return lastKeyFrame.translation
        }
        
        time = fmod(time, lastKeyFrame.time)
        let keyFramePairs = translationKeyFrames.indices.dropFirst().map {
            (previous: translationKeyFrames[$0 - 1], next: translationKeyFrames[$0])
        }
        
        guard let (previousKey, nextKey) = keyFramePairs.first(where: {
            time < $0.next.time
        }) else {
            print("couldn't find any appropriate key paird")
            return nil
        }
        
        let interpolant = (time - previousKey.time) / (nextKey.time - previousKey.time)
        
        let translation = simd_mix(previousKey.translation,
                                   nextKey.translation,
                                   float3(repeating: interpolant))
        
        return translation
    }
    
    func getRotation(at inputTime: Float) -> simd_quatf? {
        guard let lastKeyFrame = rotationKeyFrames.last else {
            print("Last translation key frame was nil")
            return nil
        }
        
        var time = inputTime
        if let firstKeyFrame = rotationKeyFrames.first,
            time <= firstKeyFrame.time {
            return firstKeyFrame.rotationQuatf
        }
        
        if time >= lastKeyFrame.time,
           !repeatAnimation {
            return lastKeyFrame.rotationQuatf
        }
        
        time = fmod(time, lastKeyFrame.time)
        let keyFramePairs = rotationKeyFrames.indices.dropFirst().map {
            (previous: rotationKeyFrames[$0 - 1], next: rotationKeyFrames[$0])
        }
        
        guard let (previousKey, nextKey) = keyFramePairs.first(where: {
            time < $0.next.time
        }) else {
            print("couldn't find any appropriate key paird")
            return nil
        }
        
        let interpolant = (time - previousKey.time) / (nextKey.time - previousKey.time)
        
        let rotationQuatf = simd_slerp(previousKey.rotationQuatf,
                                       nextKey.rotationQuatf,
                                       interpolant)
        
        return rotationQuatf
    }
    
    func getScale(at inputTime: Float) -> float3? {
        guard let lastKeyFrame = scaleKeyFrames.last else {
            print("Last translation key frame was nil")
            return nil
        }
        
        var time = inputTime
        if let firstKeyFrame = scaleKeyFrames.first,
            time <= firstKeyFrame.time {
            return firstKeyFrame.scale
        }
        
        if time >= lastKeyFrame.time,
           !repeatAnimation {
            return lastKeyFrame.scale
        }
        
        time = fmod(time, lastKeyFrame.time)
        let keyFramePairs = scaleKeyFrames.indices.dropFirst().map {
            (previous: scaleKeyFrames[$0 - 1], next: scaleKeyFrames[$0])
        }
        
        guard let (previousKey, nextKey) = keyFramePairs.first(where: {
            time < $0.next.time
        }) else {
            print("couldn't find any appropriate key paird")
            return nil
        }
        
        let interpolant = (time - previousKey.time) / (nextKey.time - previousKey.time)
        
        let scale = simd_mix(previousKey.scale,
                             nextKey.scale,
                             float3(repeating: interpolant))
        
        return scale
    }
    
}


struct SkeletonAnimation {
    var name: String = ""
    var jointsAnimationAtKeyFrame: [String: AnimationWithKeyFrames] = [:]
    
    
}

struct AnimationHelpers {
    static func loadAnimation(packedAnimation: MDLPackedJointAnimation) -> SkeletonAnimation {
        var skeletonAnimation = SkeletonAnimation()
        skeletonAnimation.name = URL(string: packedAnimation.name)?.lastPathComponent ?? "Untitled"
        
        for (joinedIndex, joinedPath) in packedAnimation.jointPaths.enumerated() {
            var jointAnimation = AnimationWithKeyFrames()
            
            let translationTimes = packedAnimation.translations.times
            for i in 0..<packedAnimation.translations.times.count {
                let time = Float(translationTimes[i])
                let animationArrayPosition = i * packedAnimation.jointPaths.count + joinedIndex
                jointAnimation.translationKeyFrames.append(
                    TranslationKeyFrame(time: time, translation: packedAnimation.translations.float3Array[animationArrayPosition])
                )
            }
            
            let rotationTimes = packedAnimation.rotations.times
            for i in 0..<packedAnimation.rotations.times.count {
                let time = Float(rotationTimes[i])
                let animationArrayPosition = i * packedAnimation.jointPaths.count + joinedIndex
                jointAnimation.rotationKeyFrames.append(
                    RotationKeyFrame(time: time, rotationQuatf: packedAnimation.rotations.floatQuaternionArray[animationArrayPosition])
                )
            }
            
            let scaleTimes = packedAnimation.scales.times
            for i in 0..<packedAnimation.scales.times.count {
                let time = Float(scaleTimes[i])
                let animationArrayPosition = i * packedAnimation.jointPaths.count + joinedIndex
                jointAnimation.scaleKeyFrames.append(
                    ScaleKeyFrame(time: time, scale: packedAnimation.scales.float3Array[animationArrayPosition])
                )
            }
            
            skeletonAnimation.jointsAnimationAtKeyFrame[joinedPath] = jointAnimation
        }
        
        return skeletonAnimation
    }
}
