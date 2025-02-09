//
//  TabBarController.swift
//  VDTransition
//
//  Created by Данил Войдилов on 02.04.2021.
//

import UIKit

extension UITabBarController: CustomTransitionViewController {
	
	public var defaultInteractive: TransitionInteractivity? { nil }
	
	public var applyModifierOnBothViews: Bool { true }
	
	public var defaultDelegate: AnyObject? {
		get { delegate }
		set { delegate = newValue as? UITabBarControllerDelegate }
	}
	
	public func setTransition(delegate: VDTransitioningDelegate) {
		self.delegate = delegate
	}
}

extension VDTransitioningDelegate: UITabBarControllerDelegate {
	
	public var previousTabDelegate: UITabBarControllerDelegate? {
		previousDelegate as? UITabBarControllerDelegate
	}
	
	open func tabBarController(_ tabBarController: UITabBarController, interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
		transitioning(for: tabBarController, interactionControllerFor: animationController)
	}
	
	open func tabBarController(_ tabBarController: UITabBarController, animationControllerForTransitionFrom fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		guard let current = tabBarController.viewControllers?.firstIndex(of: fromVC), let next = tabBarController.viewControllers?.firstIndex(of: toVC), current != next else { return nil }
		return transitioning(for: current < next ? .next : .previous, presenting: toVC)
	}
	
	open func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
		previousTabDelegate?.tabBarController?(tabBarController, shouldSelect: viewController) ?? true
	}
	
	open func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
		previousTabDelegate?.tabBarController?(tabBarController, didSelect: viewController)
	}
	
	open func tabBarController(_ tabBarController: UITabBarController, willBeginCustomizing viewControllers: [UIViewController]) {
		previousTabDelegate?.tabBarController?(tabBarController, willBeginCustomizing: viewControllers)
	}
	
	open func tabBarController(_ tabBarController: UITabBarController, willEndCustomizing viewControllers: [UIViewController], changed: Bool) {
		previousTabDelegate?.tabBarController?(tabBarController, willEndCustomizing: viewControllers, changed: changed)
	}
	
	open func tabBarController(_ tabBarController: UITabBarController, didEndCustomizing viewControllers: [UIViewController], changed: Bool) {
		previousTabDelegate?.tabBarController?(tabBarController, didEndCustomizing: viewControllers, changed: changed)
	}
	
	open func tabBarControllerSupportedInterfaceOrientations(_ tabBarController: UITabBarController) -> UIInterfaceOrientationMask {
		previousTabDelegate?.tabBarControllerSupportedInterfaceOrientations?(tabBarController) ?? .all
	}
	
	open func tabBarControllerPreferredInterfaceOrientationForPresentation(_ tabBarController: UITabBarController) -> UIInterfaceOrientation {
		previousTabDelegate?.tabBarControllerPreferredInterfaceOrientationForPresentation?(tabBarController) ?? .portrait
	}
}
