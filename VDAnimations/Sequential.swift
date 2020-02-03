//
//  Sequential.swift
//  SuperAnimations
//
//  Created by crypto_user on 20/09/2019.
//  Copyright © 2019 crypto_user. All rights reserved.
//

import Foundation

public struct Sequential: AnimationProviderProtocol {
    private let animations: [AnimationProviderProtocol]
    public var asModifier: AnimationModifier {
        AnimationModifier(modificators: AnimationOptions.empty.chain.duration[fullDuration], animation: self)
    }
    private let fullDuration: AnimationDuration?
    
    public init(_ animations: [AnimationProviderProtocol]) {
        self.animations = animations
        self.fullDuration = Sequential.fullDuration(for: animations)
    }
    
    public init(_ animations: AnimationProviderProtocol...) {
        self = .init(animations)
    }
    
    public init(@AnimatorBuilder _ animations: () -> [AnimationProviderProtocol]) {
        self = .init(animations())
    }
    
    public func start(with options: AnimationOptions, _ completion: @escaping (Bool) -> ()) {
        guard !animations.isEmpty else {
            completion(true)
            return
        }
        guard animations.count > 1 else {
            animations[0].start(with: options, completion)
            return
        }
        let array = getOptions(for: options)
        start(index: 0, options: array, completion)
    }
    
    private func start(index: Int, options: [AnimationOptions], _ completion: @escaping (Bool) -> ()) {
        guard index < animations.count else {
            completion(true)
            return
        }
        let i = index//reversed ? animations.count - index - 1 : index
        animations[i].start(with: options[i]) {
            guard $0 else {
                return completion(false)
            }
            self.start(index: index + 1, options: options, completion)
        }
    }
    
    public func canSet(state: AnimationState) -> Bool {
        switch state {
        case .start, .end:
            return animations.reduce(while: { $0 }, true, { $0 && $1.canSet(state: state) })
        case .progress(let k):
            let array = getProgresses(animations.map({ $0.modificators }), duration: fullDuration?.absolute ?? 0, options: .empty)
            var result = true
            for i in 0..<array.count {
                if array[i].upperBound <= k || array[i].upperBound == 0 {
                    result = result && animations[i].canSet(state: .end)
                } else if array[i].lowerBound >= k {
                    result = result && animations[i].canSet(state: .start)
                } else {
                    result = result && animations[i].canSet(state: .progress((k - array[i].lowerBound) / (array[i].upperBound - array[i].lowerBound)))
                }
                if !result { return false }
            }
            return true
        }
    }
    
    public func set(state: AnimationState) {
        switch state {
        case .start, .end:
            animations.forEach { $0.set(state: state) }
        case .progress(let k):
            guard !animations.isEmpty else { return }
            let array = getProgresses(animations.map({ $0.modificators }), duration: fullDuration?.absolute ?? 0, options: .empty)
            var n: Int?
            for i in 0..<array.count {
                if array[i].upperBound <= k || array[i].upperBound == array[i].lowerBound {
                    animations[i].set(state: .end)
                } else if array[i].lowerBound >= k {
                    animations[i].set(state: .start)
                } else {
                    n = i
                }
            }
            if let i = n {
                animations[i].set(state: .progress((k - array[i].lowerBound) / (array[i].upperBound - array[i].lowerBound)))
            }
        }
    }
    
    private func getOptions(for options: AnimationOptions) -> [AnimationOptions] {
//        var options = options
//        options.repeatCount = 1
        if let dur = options.duration?.absolute {
            return setDuration(duration: dur, options: options)
        } else {
            let full = fullDuration?.absolute ?? 0
            return setDuration(duration: full, options: options)
        }
    }
    
    private static func fullDuration(for array: [AnimationProviderProtocol]) -> AnimationDuration? {
        guard array.contains(where: { $0.modificators.duration?.absolute != 0 }) else { return nil }
        let dur = array.reduce(0, { $0 + ($1.modificators.duration?.absolute ?? 0) })
        var rel = min(1, array.reduce(0, { $0 + ($1.modificators.duration?.relative ?? 0) }))
        rel = rel == 1 ? 0 : rel
        let full = dur / (1 - rel)
        return .absolute(full)
    }
    
    private func setDuration(duration full: TimeInterval, options: AnimationOptions) -> [AnimationOptions] {
        guard full > 0 else { return [AnimationOptions](repeating: options, count: animations.count) }
        var ks: [Double?] = []
        var childrenRelativeTime = 0.0
        for anim in animations {
            var k: Double?
            if let absolute = anim.modificators.duration?.absolute {
                k = absolute / full
            } else if let relative = anim.modificators.duration?.relative {
                k = relative
            }
            childrenRelativeTime += k ?? 0
            ks.append(k)
        }
        let cnt = ks.filter({ $0 == nil }).count
        let relativeK = cnt > 0 ? max(1, childrenRelativeTime) : childrenRelativeTime
        var add = (1 - min(1, childrenRelativeTime))
        if cnt > 0 {
            add /= Double(cnt)
        }
        var result: [AnimationOptions]
        if relativeK == 0 {
            result = [AnimationOptions](repeating: options.chain.duration[.absolute(full / Double(animations.count))], count: animations.count)
        } else {
            result = ks.map({ options.chain.duration[.absolute(full * ($0 ?? add) / relativeK)] })
        }
        setCurve(&result, duration: full, options: options)
        return result
    }
    
    private func setCurve(_ array: inout [AnimationOptions], duration: Double, options: AnimationOptions) {
        guard let fullCurve = options.curve, fullCurve != .linear else { return }
        let progresses = getProgresses(array, duration: duration, options: options)
        for i in 0..<animations.count {
            var (curve1, newDuration) = fullCurve.split(range: progresses[i])
            if let curve2 = animations[i].modificators.curve {
                curve1 = BezierCurve.between(curve1, curve2)
            }
            array[i].duration = .absolute(duration * newDuration)
            array[i].curve = curve1
        }
    }

    private func getProgresses(_ array: [AnimationOptions], duration: Double, options: AnimationOptions) -> [ClosedRange<Double>] {
        guard !array.isEmpty else { return [] }
        guard duration > 0 else {
            return Array(repeating: 0...0, count: array.count)
        }
        var progresses: [ClosedRange<Double>] = []
        var dur = 0.0
        var start = 0.0
        for anim in array {
            if let rel = anim.duration?.relative {
                dur += min(1, max(0, rel)) * duration
            } else {
                dur += anim.duration?.absolute ?? 0
            }
            let end = min(1, dur / duration)
            progresses.append(start...end)
            start = end
        }
        progresses[progresses.count - 1] = progresses[progresses.count - 1].lowerBound...1
        return progresses
    }
    
}
