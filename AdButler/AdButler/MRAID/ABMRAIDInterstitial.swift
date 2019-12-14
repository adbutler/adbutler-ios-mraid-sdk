//
//  ABMRAIDInterstitial.swift
//  AdButler
//

//  Copyright © 2018 AdButler, Inc. All rights reserved.
//

import Foundation
import WebKit

public class ABMRAIDInterstitial : UIViewController, MRAIDDelegate {
    public var interstitial:ABInterstitial!
    public var delegate:ABInterstitialDelegate!
    private var placement:Placement!
    private var mraidView:WKWebView!
    private var mraidHandler:MRAIDHandler!
    private var originalRootController:UIViewController!
    
    public func initialize(placement:Placement, parentViewController:UIViewController, interstitial:ABInterstitial){
        self.placement = placement
        self.interstitial = interstitial
        if(placement.body != nil){
            var renderBody = placement.body!
            MRAIDUtilities.validateHTML(&renderBody)
            parentViewController.addChild(self)
            
            mraidHandler = MRAIDHandler()
            mraidHandler.initialize(parentViewController: self, mraidDelegate: self)
            
            let config = WKWebViewConfiguration()
            config.allowsInlineMediaPlayback = true
            mraidView = WKWebView(frame:view.frame, configuration:config)
            //mraidView = WKWebView()
            mraidHandler.activeWebView = mraidView
            mraidView.uiDelegate = mraidHandler
            mraidView.navigationDelegate = mraidHandler
            mraidView.scrollView.isScrollEnabled = false
            mraidView.translatesAutoresizingMaskIntoConstraints = false
            
            mraidView.isOpaque = true
            mraidView.isUserInteractionEnabled = true
            
            mraidHandler.setMRAIDPlacementType(PlacementTypes.INTERSTITIAL)
            view.addSubview(mraidView)
            mraidView.loadHTMLString(renderBody, baseURL:nil)
            setInitialConstraints()
            originalRootController = UIApplication.shared.delegate?.window??.rootViewController
        }
    }
    
    // webview should always be the same size as the main view
    private func setInitialConstraints(){
        let webViewSizeConstraints = [
            NSLayoutConstraint(item:view as Any, attribute: .width, relatedBy: .equal, toItem: mraidView, attribute: .width, multiplier:1.0, constant:0),
            NSLayoutConstraint(item:view as Any, attribute: .height, relatedBy: .equal, toItem: mraidView, attribute: .height, multiplier:1.0, constant:0),
            NSLayoutConstraint(item:view as Any, attribute: .centerX, relatedBy: .equal, toItem: mraidView, attribute: .centerX, multiplier:1.0, constant:0),
            NSLayoutConstraint(item:view as Any, attribute: .centerY, relatedBy: .equal, toItem: mraidView, attribute: .centerY, multiplier:1.0, constant:0),
            ]
        view.addConstraints(webViewSizeConstraints)
    }
    
    public override var prefersStatusBarHidden: Bool { return true }
    
    public func display(){
        if(mraidHandler != nil){
            removeFromParent()
            setRootController(self)
            mraidHandler.setCurrentPosition(view.frame)
            mraidHandler.setIsViewable(true)
            addCloseButton(action:#selector(closeClicked))
        }
    }
    
    func setRootController(_ controller:UIViewController){
        UIApplication.shared.delegate?.window??.addSubview(controller.view)
        UIApplication.shared.delegate?.window??.rootViewController = controller
    }
    
    // only works when this is the root view controller
    public override var shouldAutorotate: Bool{
        return true// mraidHandler.orientationProperties.allowOrientationChange ?? true
    }
    
    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return mraidHandler.orientationMask
    }
    
    public func open(_ url: String) {
        let browser = MRAIDBrowserWindow()
        browser.initialize()
        browser.loadUrl(url)
        browser.onClose(perform:{() in
            // close code?
        })
        addChild(browser)
        view.addSubview(browser.view)
        self.placement!.recordClick()
    }
    
    @objc func closeClicked(){
        close()
    }
    
    public func close() {
        mraidHandler.setMRAIDState(States.HIDDEN)
        mraidHandler.setIsViewable(false)
        setRootController(originalRootController)
        mraidView = nil
        mraidHandler = nil
        originalRootController = nil
        delegate = nil
        placement = nil
    }
    
    public func expand(_ url: String?) {
        // not applicable to interstitial
    }
    
    public func resize(to: ResizeProperties) {
        // not applicable to interstitial
    }
    
    public func playVideo(_ url: String) {
        // not applicable to interstitial
    }
    
    public func reportDOMSize(_ args: String?) {
        // not applicable to interstitial
    }
    
    public func webViewLoaded() {
        delegate?.interstitialReady(interstitial)
    }
    
    public func addCloseButton(action:Selector) {
        let w = view.bounds.width
        let closeW = CGFloat(50)
        let closeH = CGFloat(50)
        
        let closeX = w - closeW
        let closeY = view.bounds.minY + 3
        let buttonRect = CGRect(x:closeX, y:closeY, width:closeW, height:closeH)
        
        let closeButton = UIButton(frame:buttonRect)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        
        let custom = mraidHandler.getExpandProperties()?.useCustomClose
        if(custom != nil && custom == false){
            closeButton.setTitleColor(UIColor.white, for:UIControl.State.normal)
            closeButton.setBackgroundImage(UIImage(named:"closeButtonBG", in: Bundle(identifier:"phunware.ios.mraid.sdk"), compatibleWith:nil), for: UIControl.State.normal)
            closeButton.setTitle("X", for:UIControl.State.normal)
            closeButton.titleLabel!.textAlignment = NSTextAlignment.center
            closeButton.titleLabel!.font = UIFont.init(descriptor: UIFontDescriptor(name:"Gill Sans", size:24.0), size: 24.0)
        }
        closeButton.addTarget(self, action: action, for:UIControl.Event.touchUpInside)
        
        view.addSubview(closeButton)
        if #available(iOS 11.0, *) {
            let guide = view.safeAreaLayoutGuide
            NSLayoutConstraint.activate([closeButton.topAnchor.constraint(equalToSystemSpacingBelow: guide.topAnchor, multiplier: 1.0)])
        } else {
            NSLayoutConstraint.activate([closeButton.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor)])
        }
        //
        //        NSLayoutConstraint.activate([closeButton.topAnchor.constraint(equalTo: view.topAnchor)])
        NSLayoutConstraint.activate([closeButton.rightAnchor.constraint(equalTo: view.rightAnchor)])
    }
    
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator){
        var degrees = 0
        switch(UIDevice.current.orientation){
        case UIDeviceOrientation.portrait:
            degrees = 0
        case UIDeviceOrientation.landscapeLeft:
            degrees = 90
        case UIDeviceOrientation.landscapeRight:
            degrees = -90
        case UIDeviceOrientation.portraitUpsideDown:
            degrees = 180
        default:
            break
        }
        let js = """
        window.__defineGetter__('orientation',function(){return \(degrees);});
        (function(){
        var event = document.createEvent('Events');
        event.initEvent('orientationchange', true, false);
        window.dispatchEvent(event);
        })();
        """
        if(mraidHandler.state == States.RESIZED){
            close()
        }
        self.mraidHandler.setMRAIDScreenSize(size)
        self.mraidHandler.setCurrentPosition(CGRect(x:0, y:0, width:size.width, height:size.height))
        coordinator.animate(alongsideTransition: { (_) in }, completion: { _ in
            self.mraidView.evaluateJavaScript(js, completionHandler: nil)
            self.mraidHandler.setMRAIDSizeChanged(to:size)
        })
    }
}
