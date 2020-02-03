//
//  Parallel.swift
//  CA
//
//  Created by crypto_user on 16.01.2020.
//  Copyright © 2020 Voidilov. All rights reserved.
//

import Foundation

public struct Parallel: AnimationProviderProtocol {
    private let animations: [AnimationProviderProtocol]
    public var asModifier: AnimationModifier {
        AnimationModifier(modificators: AnimationOptions.empty.chain.duration[maxDuration], animation: self)
    }
    private let maxDuration: AnimationDuration?
    
    private init(_ animations: [AnimationProviderProtocol]) {
        self.animations = animations
        self.maxDuration = Parallel.maxDuration(for: animations)
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
        let parallelCompletion = ParallelCompletion(animations.enumerated().map { arg in
            { arg.element.start(with: array[arg.offset], $0) }
        })
        parallelCompletion.start(completion: completion)
    }
    
    public func canSet(state: AnimationState) -> Bool {
        switch state {
        case .start, .end:
            return animations.reduce(while: { $0 }, true, { $0 && $1.canSet(state: state) })
        case .progress(let k):
            let array = getProgresses(animations.map({ $0.modificators }), duration: maxDuration?.absolute ?? 0, options: .empty)
            var result = true
            for i in 0..<array.count {
                if array[i].upperBound <= k || array[i].upperBound == 0 {
                    result = result && animations[i].canSet(state: .end)
                } else if array[i].lowerBound >= k {
                    result = result && animations[i].canSet(state: .start)
                } else {
                    result = result && animations[i].canSet(state: .progress(k / array[i].upperBound))
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
            let array = getProgresses(animations.map({ $0.modificators }), duration: maxDuration?.absolute ?? 0, options: .empty)
            for i in 0..<array.count {
                if array[i].upperBound <= k || array[i].upperBound == 0 {
                    animations[i].set(state: .end)
                } else if array[i].lowerBound >= k {
                    animations[i].set(state: .start)
                } else {
                    animations[i].set(state: .progress(k / array[i].upperBound))
                }
            }
        }
    }
    
    private func getOptions(for options: AnimationOptions) -> [AnimationOptions] {
        guard !animations.isEmpty else { return [] }
        if let dur = options.duration?.absolute {
            return setDuration(duration: dur, options: options)
        } else {
            let dur = animations.reduce(0, { max($0, $1.modificators.duration?.absolute ?? 0) })
            return setDuration(duration: dur, options: options)
        }
    }
    
    private func setDuration(duration full: TimeInterval, options: AnimationOptions) -> [AnimationOptions] {
        guard !animations.isEmpty else { return [] }
        let maxDuration = self.maxDuration?.absolute ?? 0
        let k = maxDuration == 0 ? 1 : full / maxDuration
        let childrenDurations: [Double] = animations.map {
            guard let setted = $0.modificators.duration else {
                return full
            }
            switch setted {
            case .absolute(let time):   return time * k
            case .relative(let r):      return full * min(1, r)
            }
        }
        var result = childrenDurations.map({ options.chain.duration[.absolute($0)] })
        setCurve(&result, duration: full, options: options)
        return result
    }
    
    private static func maxDuration(for array: [AnimationProviderProtocol]) -> AnimationDuration? {
        guard array.contains(where: { $0.modificators.duration?.absolute != 0 }) else { return nil }
        let maxDuration = array.reduce(0, { max($0, $1.modificators.duration?.absolute ?? 0) })
        return .absolute(maxDuration)
    }
    
    private func setCurve(_ array: inout [AnimationOptions], duration: Double, options: AnimationOptions) {
        guard let fullCurve = options.curve, fullCurve != .linear else {
            return
        }
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
            return Array(repeating: 0...1, count: array.count)
        }
        var progresses: [ClosedRange<Double>] = []
        for anim in array {
            let end: Double
            if let relative = anim.duration?.relative {
                end = min(1, max(0, relative))
            } else {
                end = (anim.duration?.absolute ?? 0) / duration
            }
            progresses.append(0...end)
        }
        return progresses
    }
    
}

fileprivate final class ParallelCompletion {
    typealias T = (Bool) -> ()
    let common: Int
    var current = 0
    let functions: [(@escaping T) -> ()]
    
    init(_ functions: [(@escaping T) -> ()]) {
        self.common = functions.count
        self.functions = functions
    }
    
    func start(completion: @escaping T) {
        for function in functions {
            function { state in
                self.current += 1
                if self.current == self.common {
                    self.current = 0
                    completion(state)
                }
            }
        }
    }
    
}
