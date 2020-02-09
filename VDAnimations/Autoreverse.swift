//
//  Autoreverse.swift
//  CA
//
//  Created by Daniil on 09.02.2020.
//  Copyright © 2020 Voidilov. All rights reserved.
//

import Foundation

public struct Autoreverse<Animation: AnimationProviderProtocol>: AnimationProviderProtocol {
    private let animation: Animation
    
    init(_ animation: Animation) {
        self.animation = animation
    }
    
    public func start(with options: AnimationOptions, _ completion: @escaping (Bool) -> ()) {
        animation.start(with: self.options(from: options, step: .forward)) {
            guard $0 else { return completion(false) }
            self.animation.start(with: self.options(from: options, step: .back), completion)
        }
    }
    
    public func set(state: AnimationState, for options: AnimationOptions) {
        let option = options.chain.autoreverseStep[nil]
        switch state {
        case .start, .end:
            animation.set(state: .start, for: option)
        case .progress(let k):
            let progress = abs(k - 0.5) * 2
            animation.set(state: .progress(progress), for: option)
        }
    }
    
    public func canSet(state: AnimationState, for options: AnimationOptions) -> Bool {
        let option = options.chain.autoreverseStep[nil]
        switch state {
        case .start, .end:
            return animation.canSet(state: .start, for: option)
        case .progress(let k):
            let progress = abs(k - 0.5) * 2
            return animation.canSet(state: .progress(progress), for: option)
        }
    }
    
    private func options(from options: AnimationOptions, step: AutoreverseStep) -> AnimationOptions {
        var result = options
        setCurve(for: &result, step: step)
        result.autoreverseStep = step
        return result
    }
    
    private func setCurve(for options: inout AnimationOptions, step: AutoreverseStep) {
        guard let duration = options.duration else { return }
        guard let fullCurve = options.curve, fullCurve != .linear else {
            options.duration = duration / 2
            return
        }
        let progress = step == .forward ? 0...0.5 : 0.5...1
        var (curve1, newDuration) = fullCurve.split(range: progress)
        if let curve2 = animation.modificators.curve {
            curve1 = BezierCurve.between(curve1, curve2)
        }
        options.duration = duration * newDuration
        options.curve = curve1
    }
    
}
