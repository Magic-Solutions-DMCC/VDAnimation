//
//  AnimateProperty.swift
//  CA
//
//  Created by Daniil on 03.02.2020.
//  Copyright © 2020 Voidilov. All rights reserved.
//

import Foundation

public struct RepeatAnimation<A: AnimationProviderProtocol>: AnimationProviderProtocol {
    private let count: Int?
    private let animation: A
    public var asModifier: AnimationModifier {
        AnimationModifier(modificators: AnimationOptions.empty.chain.duration[duration], animation: self)
    }
    private let duration: AnimationDuration?
    
    init(_ cnt: Int?, for anim: A) {
        count = cnt
        animation = anim
        duration = nil
    }
    
    public func start(with options: AnimationOptions, _ completion: @escaping (Bool) -> ()) {
        if let i = count {
            let cnt = max(0, i)
            guard cnt > 0 else {
                completion(true)
                return
            }
            let option = options.chain.duration[RepeatAnimation.duration(for: cnt, from: options.duration ?? duration)]
            start(with: option, completion, i: 0, condition: { $0 < cnt })
        } else {
            start(with: options, completion, i: 0, condition: { _ in true })
        }
    }
    
    private func start(with options: AnimationOptions, _ completion: @escaping (Bool) -> (), i: Int, condition: @escaping (Int) -> Bool) {
        guard condition(i) else {
            completion(true)
            return
        }
        if i > 0, animation.canSet(state: .start) {
            animation.set(state: .start)
        }
        animation.start(with: options) {
            if $0 {
                self.start(with: options, completion, i: i &+ 1, condition: condition)
            } else {
                completion($0)
            }
        }
    }
    
    public func canSet(state: AnimationState) -> Bool {
        switch state {
        case .start, .end: return animation.canSet(state: state)
        case .progress(let k):
            if count != nil {
                return animation.canSet(state: .progress(getProgress(for: k)))
            } else {
                return animation.canSet(state: state)
            }
        }
    }
    
    public func set(state: AnimationState) {
        switch state {
        case .start, .end:
            animation.set(state: state)
        case .progress(let k):
            if count != nil {
                animation.set(state: .progress(getProgress(for: k)))
            } else {
                animation.set(state: state)
            }
        }
    }
    
    private func getProgress(for progress: Double) -> Double {
        guard let cnt = count, cnt > 0 else { return progress }
        return (progress * Double(cnt)).truncatingRemainder(dividingBy: 1)
    }
    
    private static func duration(for count: Int?, from dur: AnimationDuration?) -> AnimationDuration? {
        
    }
    
}
