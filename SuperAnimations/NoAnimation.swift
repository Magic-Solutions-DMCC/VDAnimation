//
//  NoAnimation.swift
//  SuperAnimations
//
//  Created by crypto_user on 25/09/2019.
//  Copyright © 2019 crypto_user. All rights reserved.
//

import UIKit

public final class NotAnAnimation: AnimatorProtocol {
    public var progress: Double {
        get { 1 }
        set {
            if newValue > 0 {
                block()
            }
        }
    }
    public let isRunning: Bool = false
    public let state: UIViewAnimatingState = .inactive
    public var parameters: AnimationParameters = .default
    let block: () -> ()
    
    public init(_ block: @escaping () -> ()) {
        self.block = block
        parameters.userTiming.duration = .absolute(0)
    }
    
    public func copy(with parameters: AnimationParameters) -> NotAnAnimation {
        return NotAnAnimation(block)
    }
    
    public func pause() {}
    
    public func start(_ completion: @escaping (UIViewAnimatingPosition) -> ()) {
        UIView.performWithoutAnimation(block)
        completion(.end)
    }
    
    public func stop(at position: UIViewAnimatingPosition) {}
    
}
