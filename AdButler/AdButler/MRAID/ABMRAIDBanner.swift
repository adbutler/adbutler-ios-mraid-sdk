//
//  ABMRAIDBanner.swift
//  AdButler
//

//  Copyright © 2018 AdButler, Inc. All rights reserved.
//

import WebKit
import Foundation
import JavaScriptCore
import Photos
import EventKit

public class ABMRAIDBanner: UIViewController, MRAIDDelegate {

    public var placement: Placement?
    private var mraidView: WKWebView!
    private var secondaryWebView: WKWebView?
    private var videoPlayer:ABVideoPlayer?
    internal var mraidHandler: MRAIDHandler!
    
    private var defaultPosition: CGPoint?
    private var layoutPosition: String?
    
    private var defaultSize:CGSize? = nil
    private var fallbackSize = CGSize(width:320, height:50)
    private let fullScreenSize = CGSize(width:UIScreen.main.bounds.width, height:UIScreen.main.bounds.height)
    
    private var parentController: UIViewController!
    private var previousRootController:UIViewController?
    private var originalRootController:UIViewController?
    
    private var respectSafeArea:Bool = false
    
    public func initialize(placement:Placement, parentViewController:UIViewController, position:String, respectSafeArea:Bool = false){
        initialize(placement:placement, parentViewController:parentViewController, position:position, frame:nil, respectSafeArea:respectSafeArea)
    }
    
    public func initialize(placement:Placement, parentViewController:UIViewController, frame:CGRect, respectSafeArea:Bool = false){
        initialize(placement:placement, parentViewController:parentViewController, position:nil, frame:frame, respectSafeArea:respectSafeArea)
    }
    
    private func initialize(placement:Placement, parentViewController:UIViewController, position:String?, frame:CGRect?, respectSafeArea:Bool = false){
        self.placement = placement
        self.parentController = parentViewController
        self.respectSafeArea = respectSafeArea
        if(placement.body != nil){
            var renderBody = placement.body!
            initBanner()
            MRAIDUtilities.validateHTML(&renderBody)
            
            let url = Bundle(identifier:"adbutler.ios.mraid.sdk")?.bundleURL
            mraidView.loadHTMLString(renderBody, baseURL:url)
            originalRootController = UIApplication.shared.delegate?.window??.rootViewController
            if(position != nil){
                addAsChild(to:parentViewController, position:position!)
            }else if(frame != nil){
                addAsChild(to:parentViewController, frame:frame!)
            }
        }
    }
    
    func initBanner(){
        view.backgroundColor = UIColor.white
        initWebView()
    }
    
    public override var prefersStatusBarHidden: Bool {
        get {
            return true
        }
    }
    
    private func initWebView(){
        mraidHandler = MRAIDHandler()
        mraidHandler.respectsSafeArea = respectSafeArea
        mraidHandler.initialize(parentViewController:self, mraidDelegate:self)
        
        mraidView = WKWebView()
        mraidHandler.activeWebView = mraidView
        
        mraidView.uiDelegate = mraidHandler
        mraidView.configuration.allowsInlineMediaPlayback = true
        mraidView.navigationDelegate = mraidHandler
        mraidView.translatesAutoresizingMaskIntoConstraints = false
        mraidView.scrollView.isScrollEnabled = false
        mraidView.isOpaque = true
        mraidView.isUserInteractionEnabled = true
        
        view.addSubview(mraidView)
        setInitialConstraints()
    }
    
    private func initSecondaryWebView(_ url:String){
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        secondaryWebView = WKWebView(frame:CGRect(x:0, y:0, width:UIScreen.main.bounds.width, height:UIScreen.main.bounds.height))
        mraidHandler.activeWebView = secondaryWebView!
        mraidHandler.isExpandedView = true
        secondaryWebView!.uiDelegate = mraidHandler
        secondaryWebView!.navigationDelegate = mraidHandler
        secondaryWebView!.isUserInteractionEnabled = true
        secondaryWebView!.translatesAutoresizingMaskIntoConstraints = false
        secondaryWebView?.scrollView.isScrollEnabled = false
        parentController!.view.addSubview(secondaryWebView!)
        if #available(iOS 11.0, *) {
            secondaryWebView!.scrollView.contentInsetAdjustmentBehavior = .never
        }
        NSLayoutConstraint.activate([
            secondaryWebView!.heightAnchor.constraint(equalTo:parentController.view.heightAnchor),
            secondaryWebView!.widthAnchor.constraint(equalTo:parentController.view.widthAnchor)
            ])
        MRAIDUtilities.getExpandedUrlContent(url, completion: { val in
            DispatchQueue.main.async{
                self.mraidHandler.setMRAIDState(States.EXPANDED)
                self.secondaryWebView!.loadHTMLString(val, baseURL:nil)
            }
        })
    }
    
    public func webViewLoaded(){
        if(defaultSize == nil){
            defaultSize = fallbackSize
        }
        setSize(defaultSize!)
        mraidHandler.setDefaultPosition(CGRect(x:defaultPosition!.x, y:defaultPosition!.y, width:defaultSize!.width, height:defaultSize!.height))
        mraidHandler.setCurrentPosition(CGRect(x:defaultPosition!.x, y:defaultPosition!.y, width:defaultSize!.width, height:defaultSize!.height))
        setPosition(defaultPosition!)
        mraidHandler.setIsViewable(true)
    }
    
    private func addAsChild(to parent:UIViewController, position:String){
        view.frame = CGRect(x:0, y:0, width:0, height:0)
        parent.view.addSubview(view)
        previousRootController = originalRootController
        parentController.addChild(self)
        let size = CGSize(width:placement!.width, height:placement!.height)
        if(size.width > 0 && size.height > 0){
            defaultSize = size
            // setting mraid default will happen at setSize
        }
        view.translatesAutoresizingMaskIntoConstraints = false
        layoutPosition = position
        setResizeMask()
        if #available(iOS 11.0, *){
            mraidView!.scrollView.contentInsetAdjustmentBehavior = .never
        }
    }
    
    private func addAsChild(to parent:UIViewController, frame:CGRect){
        defaultPosition = CGPoint(x:frame.minX, y:frame.minY)
        defaultSize = CGSize(width:frame.width, height:frame.height)
        mraidHandler.setDefaultPosition(frame)
        mraidHandler.setCurrentPosition(frame)
    }
    
    private func setResizeMask(){
        let standardSpacing: CGFloat = 8.0

        
        if(layoutPosition! == "center"){
            NSLayoutConstraint.activate([view.centerXAnchor.constraint(equalTo: parentController.view.centerXAnchor),
                                         view.centerYAnchor.constraint(equalTo: parentController.view.centerYAnchor)])
        }else{
            if(layoutPosition!.range(of:"top") != nil){
                if(mraidHandler.respectsSafeArea){
                    if #available(iOS 11.0, *) {
                        let guide = parentController.view.safeAreaLayoutGuide
                        NSLayoutConstraint.activate([view.topAnchor.constraint(equalToSystemSpacingBelow: guide.topAnchor, multiplier: 1.0)])
                    } else {
                        NSLayoutConstraint.activate([view.topAnchor.constraint(equalTo: parentController.topLayoutGuide.bottomAnchor, constant: standardSpacing)])
                    }
                } else{
                    NSLayoutConstraint.activate([view.topAnchor.constraint(equalTo: parentController.view.topAnchor)])
                }
                if(layoutPosition!.range(of:"center") != nil){
                    NSLayoutConstraint.activate([view.centerXAnchor.constraint(equalTo: parentController.view.centerXAnchor)])
                }
            }
            if(layoutPosition!.range(of:"bottom") != nil){
                if(mraidHandler.respectsSafeArea){
                    if #available(iOS 11.0, *) {
                        let guide = parentController.view.safeAreaLayoutGuide
                        NSLayoutConstraint.activate([view.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: 0)])
                    } else {
                        NSLayoutConstraint.activate([view.bottomAnchor.constraint(equalTo: parentController.bottomLayoutGuide.topAnchor, constant: standardSpacing)])
                    }
                } else{
                    NSLayoutConstraint.activate([view.bottomAnchor.constraint(equalTo: parentController.view.bottomAnchor)])
                }
                if(layoutPosition!.range(of:"center") != nil){
                    NSLayoutConstraint.activate([view.centerXAnchor.constraint(equalTo: parentController.view.centerXAnchor)])
                }
            }
            if(layoutPosition!.range(of:"left") != nil){
                NSLayoutConstraint.activate([view.leftAnchor.constraint(equalTo: parentController.view.leftAnchor)])
                if(layoutPosition!.range(of:"center") != nil){
                    NSLayoutConstraint.activate([view.centerYAnchor.constraint(equalTo: parentController.view.centerYAnchor)])
                }
            }
            if(layoutPosition!.range(of:"right") != nil){
                NSLayoutConstraint.activate([view.rightAnchor.constraint(equalTo: parentController.view.rightAnchor)])
                if(layoutPosition!.range(of:"center") != nil){
                    NSLayoutConstraint.activate([view.centerYAnchor.constraint(equalTo: parentController.view.centerYAnchor)])
                }
            }
        }
    }
    
    @objc func onCloseExpandedClicked(sender: UIButton!){
        close()
    }
    
    @objc func onCloseVideoClicked(){
        setRootController(previousRootController!)
        videoPlayer = nil
    }
    
    func customCloseClicked(){
        close()
    }
    
    func setRootController(_ controller:UIViewController){
        previousRootController = UIApplication.shared.delegate?.window??.rootViewController
        UIApplication.shared.delegate?.window??.addSubview(controller.view)
        UIApplication.shared.delegate?.window??.rootViewController = controller
    }
    
    // only works when this is the root view controller
    public override var shouldAutorotate: Bool{
        if(mraidHandler.orientationProperties.forceOrientation != nil && mraidHandler.orientationProperties.forceOrientation != Orientations.NONE && UIDevice.current.value(forKey: "orientation") as! Int != Int(mraidHandler.orientationMask!.rawValue)){
            return true
        }
        return mraidHandler.orientationProperties.allowOrientationChange ?? true
    }
    
    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return mraidHandler.orientationMask
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
        if(mraidHandler.state == States.EXPANDED){
            UIView.setAnimationsEnabled(false)
            self.mraidHandler.setCurrentPosition(CGRect(x:0, y:0, width:size.width, height:size.height))
            self.mraidHandler.setMRAIDScreenSize(size)
            self.mraidHandler.setMRAIDSizeChanged(to:size)
            coordinator.animate(alongsideTransition: { (_) in }, completion: { _ in
                UIView.setAnimationsEnabled(true)
            })
        }
        
        mraidView.evaluateJavaScript(js, completionHandler: nil)
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
    
    private func setSize(_ size:CGSize ){
        view.frame = CGRect(x:view.frame.minX, y:view.frame.minY, width:size.width, height:size.height)
        view.removeConstraints(view.constraints)
        setInitialConstraints()
        NSLayoutConstraint.activate([view!.widthAnchor.constraint(equalToConstant: size.width),
                                     view!.heightAnchor.constraint(equalToConstant: size.height)])
        
        if(defaultPosition == nil && layoutPosition != nil){
            defaultPosition = getPointFromPosition(layoutPosition!)
            mraidHandler.setDefaultPosition(CGRect(x:defaultPosition!.x, y:defaultPosition!.y, width:defaultSize!.width, height:defaultSize!.height))
            mraidHandler.setCurrentPosition(CGRect(x:defaultPosition!.x, y:defaultPosition!.y, width:defaultSize!.width, height:defaultSize!.height))
        }
        mraidHandler.setMRAIDSizeChanged(to:size)
    }
    
    private func setPosition(_ point:CGPoint){
        view.frame = CGRect(x:point.x, y:point.y, width:view.frame.width, height:view.frame.height)
    }
    
    private func getPointFromPosition(_ pos:String) -> CGPoint {
        var x:CGFloat = 0
        var y:CGFloat = 0
        
        if(pos.range(of:"top") != nil){
            y = 0
        }
        if(pos.range(of:"bottom") != nil){
            y = parentController.view.bounds.height - view.bounds.height
        }
        if(pos.range(of:"center") != nil){
            x = (parentController.view.bounds.width / 2) - (view.bounds.width / 2)
            if(pos == Positions.CENTER){
                y = (parentController.view.bounds.height / 2) - (view.bounds.height / 2)
            }
        }
        if(pos.range(of:"left") != nil){
            x = 0
        }
        if(pos.range(of:"right") != nil){
            x = parentController.view.bounds.width - view.bounds.width
        }
        return CGPoint(x:x, y:y)
    }
    
    private func setFullScreen(){
        view.frame = CGRect(x:0, y:0, width:UIScreen.main.bounds.width, height:UIScreen.main.bounds.height)
        view.removeConstraints(view.constraints)
        setInitialConstraints()
        // handled in mraidHandler
//        mraidHandler.setCurrentPosition(view.frame)
//        mraidHandler.setMRAIDSizeChanged(to: fullScreenSize)
    }
    
    //  ---------------------------------------
    //  ------   MRAID DELEGATE PROTOCOl ------
    //  ---------------------------------------
    public func reportDOMSize(_ args:String?){
        do{
            if(defaultSize == nil && args != nil){
                let size:Size? = try MRAIDUtilities.deserialize(args!)
                if(size != nil){
                    if(size!.width == 0 || size!.height == 0){
                        defaultSize = fallbackSize
                    }else{
                        defaultSize = CGSize(width:size!.width, height:size!.height)
                    }
                }
            }else{
                //TODO args was nil
            }
        } catch{
            // width or height was null.. can't find size.
            if(defaultSize == nil){
                defaultSize = fallbackSize
            }
        }
    }
    
    public func expand(_ url:String?){
        if(url != nil){
            //TODO second webview
            initSecondaryWebView(url!)
        }else{
            if(mraidHandler.state != States.EXPANDED){
                setFullScreen()
                removeFromParent()
                setRootController(self)
            }
        }
    }
    
    public func open(_ url:String){
        let browser = MRAIDBrowserWindow()
        browser.initialize()
        browser.loadUrl(url)
        browser.onClose(perform:{() in
            MRAIDUtilities.setRootController(self.originalRootController!)
        })
        MRAIDUtilities.setRootController(browser)
        self.placement!.recordClick()
    }
    
    public func resize(to:ResizeProperties){
        setSize(CGSize(width:to.width!, height:to.height!))
        if(to.allowOffscreen == false){
            var x = CGFloat(0)
            var y = CGFloat(0)
            let vminX = view.frame.minX
            let vminY = view.frame.minY
            let smaxX = parentController.view.frame.maxX
            let smaxY = parentController.view.frame.maxY
            
            if(vminX <= 0){
                x = 0
            }else{
                x = min(smaxX - view.bounds.width, vminX)
            }
            
            if(vminY <= 0){
                y = 0
            }else{
                y = min(smaxY - view.bounds.height, vminY)
            }
            setPosition(CGPoint(x:x, y:y))
            mraidHandler.setCurrentPosition(CGRect(x:Int(x), y:Int(y), width:to.width!, height:to.height!))
        }else{
            setPosition(CGPoint(x:view.frame.minX + CGFloat(to.offsetX!), y:view.frame.minY + CGFloat(to.offsetY!)))
            mraidHandler.setCurrentPosition(CGRect(x:Int(defaultPosition!.x) + to.offsetX!, y:Int(defaultPosition!.y) + to.offsetY!, width:to.width!, height:to.height!))
        }
    }
    
    public func playVideo(_ urlStr:String){
        if let videoURL = URL(string:urlStr) {
            videoPlayer = ABVideoPlayer()
            setRootController(videoPlayer!)
            videoPlayer!.playVideo(videoURL, onClose: {() in
                self.onCloseVideoClicked()
            })
        }
    }
    
    public func close(){
        if(mraidHandler.state == States.RESIZED){
            setSize(defaultSize!)
            if(layoutPosition != nil){
                // we may have rotated by force, or just by user interaction while resized.
                // defualt position may be out of place.
                let point = getPointFromPosition(layoutPosition!)
                setPosition(point)
            }else{
                setPosition(defaultPosition!)
            }
            mraidHandler.setCurrentPosition(CGRect(x:defaultPosition!.x, y:defaultPosition!.y, width:defaultSize!.width, height:defaultSize!.height))
        }
        if(mraidHandler.state == States.EXPANDED){
            if(mraidHandler.activeWebView == secondaryWebView){
                mraidHandler.activeWebView = mraidView
                secondaryWebView?.removeFromSuperview()
                secondaryWebView = nil
            }else{
                UIView.setAnimationsEnabled(true)
                // re-enable the old root view controller, and add ourselves back to it.
                view.backgroundColor = nil
                setRootController(originalRootController!)
                parentController.addChild(self)
                parentController.view.addSubview(view)
            }
            setSize(defaultSize!)
            if(layoutPosition != nil){
                // we may have rotated by force, or just by user interaction while expanded.
                // defualt position may be out of place.
                let point = getPointFromPosition(layoutPosition!)
                setPosition(point)
            }else{
                setPosition(defaultPosition!)
            }
            mraidHandler.setCurrentPosition(CGRect(x:defaultPosition!.x, y:defaultPosition!.y, width:defaultSize!.width, height:defaultSize!.height))
            setResizeMask()
        }
    }
    
}
