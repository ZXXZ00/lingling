//
//  FloatViewDelegate.swift
//  
//
//  Created by Adam Zhao on 5/17/21.
//

import UIKit

public class FloatView : NSObject, UIViewControllerTransitioningDelegate {
    
    let size : CGSize

    public init(_ size: CGSize) {
        self.size = size
    }
    
    public func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return MyPresentationController(presentedViewController: presented, presentingViewController: presenting, size: size)
    }
    
}

class MyPresentationController : UIPresentationController {
    
    let size : CGSize

    let dimmingView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    
    override var frameOfPresentedViewInContainerView: CGRect {
        let bounds = presentingViewController.view.bounds
        let origin = CGPoint(x: bounds.midX - size.width/2, y: bounds.midY - size.height/2)
        return CGRect(origin: origin, size: size)
    }
    
    init(presentedViewController : UIViewController, presentingViewController: UIViewController?, size : CGSize) {
        self.size = size
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(sender:)))
        dimmingView.addGestureRecognizer(tap)
    }
    
    override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        dimmingView.frame = presentingViewController.view.frame
        dimmingView.alpha = 0
        containerView?.addSubview(dimmingView)
        presentingViewController.transitionCoordinator?.animate(alongsideTransition: { _ in self.dimmingView.alpha = 1 }, completion: nil)
    }
    
    override func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()
        presentingViewController.transitionCoordinator?.animate(alongsideTransition: { _ in self.dimmingView.alpha = 0 }, completion: { _ in self.dimmingView.removeFromSuperview() })
    }
    
    @objc func handleTap(sender: UITapGestureRecognizer) {
        presentingViewController.dismiss(animated: true, completion: nil)
    }

}
