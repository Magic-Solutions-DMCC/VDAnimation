//
//  File.swift
//  
//
//  Created by Данил Войдилов on 26.05.2021.
//

import UIKit

public protocol ViewControllerTransitable: UIViewController {}

extension UIViewController: ViewControllerTransitable {}

extension ViewControllerTransitable {
	
	public var transition: VСTransitionConfig {
		get {
			if let result = objc_getAssociatedObject(self, &transitionVCKey) as? VСTransitionConfig {
				return result
			}
			let result = VСTransitionConfig(self)
			result.isCustom = (self as? CustomTransitionViewController) != nil
			objc_setAssociatedObject(self, &transitionVCKey, result, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
			return result
		}
		set {
			newValue.vc = self
			objc_setAssociatedObject(self, &transitionVCKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
		}
	}
	
	public var presentTransition: VСTransitionConfig {
		get {
			let result = transition
			transition.isCustom = false
			return result
		}
		set {
			newValue.isCustom = false
			transition = newValue
		}
	}
}

public final class VСTransitionConfig {
	public weak var vc: UIViewController? {
		didSet {
			if isEnabled { setEnabled() }
		}
	}
	fileprivate var isCustom: Bool {
		get { delegate.isCustom }
		set { delegate.isCustom = newValue }
	}
	public private(set) lazy var delegate = VDTransitioningDelegate(vc)
	private weak var previousDelegate: UIViewControllerTransitioningDelegate?
	
	public var duration: TimeInterval {
		get { delegate.duration }
		set { delegate.duration = newValue }
	}
	public var curve: BezierCurve {
		get { delegate.curve }
		set { delegate.curve = newValue }
	}
	public var modifier: VDTransition<UIView>? {
		get { delegate.modifier }
		set { delegate.modifier = newValue }
	}
	public var parallelAnimation: TransitionParallelAnimation? {
		get { delegate.parallelAnimation }
		set { delegate.parallelAnimation = newValue }
	}
	public var interactive: TransitionInteractivity {
		get { delegate.interactivity }
		set { delegate.interactivity = newValue }
	}
	public var containerModifier: VDTransition<UIView> {
		get { delegate.containerModifier }
		set { delegate.containerModifier = newValue }
	}
	public var prepare: ((VDTransitionContext) -> Void)? {
		get { delegate.prepare }
		set { delegate.prepare = newValue }
	}
	public var inAnimation: ((VDTransitionContext) -> Void)? {
		get { delegate.inAnimation }
		set { delegate.inAnimation = newValue }
	}
	public var completion: ((VDTransitionContext, Bool) -> Void)? {
		get { delegate.completion }
		set { delegate.completion = newValue }
	}
	public var restoreDisappearedViews: Bool {
		get { delegate.restoreDisappearedViews }
		set { delegate.restoreDisappearedViews = newValue }
	}
	public var applyModifierOnBothVC: Bool {
		get { delegate.applyModifierOnBothVC }
		set { delegate.applyModifierOnBothVC = newValue }
	}
	
	public var isEnabled = false {
		didSet {
			guard isEnabled != oldValue else { return }
			if isEnabled {
				setEnabled()
			} else {
				vc?.transitioningDelegate = previousDelegate
				if delegate.previousDelegate != nil {
					(vc as? CustomTransitionViewController)?.defaultDelegate = delegate.previousDelegate
				}
			}
		}
	}
	
	private func setEnabled() {
		guard vc != nil else { return }
		delegate.owner = vc
		
		if isCustom, interactive.isNone, let defaultInteractive = (vc as? CustomTransitionViewController)?.defaultInteractive {
			interactive = defaultInteractive
		}
		
		if isCustom {
			delegate.previousDelegate = (vc as? CustomTransitionViewController)?.defaultDelegate
			(vc as? CustomTransitionViewController)?.setTransition(delegate: delegate)
		} else {
			previousDelegate = vc?.transitioningDelegate
			vc?.transitioningDelegate = delegate
			vc?.modalPresentationStyle = .overCurrentContext
		}
	}
	
	public init(_ vc: UIViewController) {
		self.vc = vc
	}
	
	public init() {}
}

private var transitionVCKey = "transitionVCKey"
