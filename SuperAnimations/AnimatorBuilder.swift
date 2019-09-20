//
//  AnimatorBuilder.swift
//  SuperAnimations
//
//  Created by crypto_user on 20/09/2019.
//  Copyright © 2019 crypto_user. All rights reserved.
//

import UIKit

@_functionBuilder
public struct AnimatorBuilder {
    
    public static func buildBlock() {
    }
    
    public static func buildBlock(_ animations: AnimatorProtocol...) -> [AnimatorProtocol] {
        return animations
    }
    
    public static func buildBlock(_ animation: AnimatorProtocol) -> AnimatorProtocol {
        return animation
    }
    
}
