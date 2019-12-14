//
//  MRAIDView.swift
//  AdButler
//

//  Copyright © 2018 AdButler, Inc. All rights reserved.
//

import Foundation
import WebKit
import JavaScriptCore
import Photos
import EventKit

public class MRAIDHandler : NSObject, WKUIDelegate, WKNavigationDelegate {
    private var mraidDelegate:MRAIDDelegate? = nil
    private var parentVC:UIViewController? = nil
    
    public var state:String = States.LOADING
    public var orientationProperties:OrientationProperties = OrientationProperties(allowOrientationChange: true, forceOrientation: Orientations.NONE)
    private var resizeProperties:ResizeProperties? = nil
    private var expandProperties:ExpandProperties? = nil
    private var supportedFeatures:[String] = []
    private var placementType:String = PlacementTypes.INLINE
    private var isViewable:Bool = false
    public var isInterstitial:Bool = false
    public var activeWebView:WKWebView! // the same handler will be used for expanded mraid webviews
    public var orientationMaskAll:UIInterfaceOrientationMask = [ .portrait , .landscapeLeft , .landscapeRight , .portraitUpsideDown ]
    public var orientationMask:UIInterfaceOrientationMask!
    private var closeButton:UIButton?
    
    public var isExpandedView:Bool = false
    
    public var debug:Bool = true
    internal var respectsSafeArea:Bool = false
    
    public func initialize(parentViewController:UIViewController, mraidDelegate:MRAIDDelegate){
        parentVC = parentViewController
        orientationMask = orientationMaskAll
        self.mraidDelegate = mraidDelegate
        getSupportedFeatures()
    }
    
    
    /* Handle HTTP requests from the webview */
    public func webView(_ webView: WKWebView,
                        decidePolicyFor navigationAction: WKNavigationAction,
                        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let url = navigationAction.request.url
        if(url != nil && url!.absoluteString != "about:blank"){
            if(url!.absoluteString.range(of:"servedbyadbutler.com") != nil){
                decisionHandler(.allow)
                return
            }else if (url!.absoluteString.range(of:"mraid://") != nil){
                let rangeMRAID = url!.absoluteString.range(of:"mraid://")
                let rangeQueryString = url!.absoluteString.range(of:"?args=")
                var endpoint = ""
                var args:String? = nil
                if(rangeQueryString == nil){
                    let from = rangeMRAID?.upperBound
                    let to = url!.absoluteString.endIndex
                    endpoint = String(url!.absoluteString[from!..<to])
                }else{
                    let from = rangeMRAID?.upperBound
                    let to = rangeQueryString!.lowerBound
                    endpoint = String(url!.absoluteString[from!..<to])
                    args = String(url!.absoluteString[rangeQueryString!.upperBound..<url!.absoluteString.endIndex])
                }
                
                handleEndpoint(endpoint, args:args)
                decisionHandler(.cancel)
                return
            }
        }
        decisionHandler(.allow)
        return
    }
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        Log("webViewDidFinishLoad")
        setMRAIDSupports(Features.CALENDAR)
        setMRAIDSupports(Features.TEL)
        setMRAIDSupports(Features.STORE_PICTURE)
        setMRAIDSupports(Features.INLINE_VIDEO)
        setMRAIDSupports(Features.SMS)
        setMRAIDScreenSize(UIScreen.main.bounds.size)
        setMRAIDMaxSize(UIScreen.main.bounds.size)
        setMRAIDVersion(MRAIDVersion)
        mraidDelegate?.webViewLoaded()
        if(self.isExpandedView){
            setMRAIDState(States.EXPANDED)
        }else{
            setMRAIDState(States.DEFAULT)
        }
        fireMRAIDEvent(Events.READY)
    }
    
    public func setMaxSize(_ size:CGSize){
        setMRAIDMaxSize(size)
    }
    
    public func setCurrentPosition(_ pos:CGRect){
        setMRAIDCurrentPosition(pos)
    }
    
    public func setDefaultPosition(_ pos:CGRect){
        setMRAIDDefaultPosition(pos)
    }
    
    private func handleEndpoint(_ endpoint:String, args:String? = nil) {
        if(endpoint != NativeEndpoints.REPORT_JS_LOG){  // too verbose
            Log("handleEndpoint (" + endpoint + ")")
        }
        
        switch(endpoint){
        case NativeEndpoints.REPORT_DOM_SIZE:
            mraidDelegate!.reportDOMSize(args)
        case NativeEndpoints.SET_ORIENTATION_PROPERTIES:
            setOrientationProperties(args)
        case NativeEndpoints.EXPAND:
            expand(args)
        case NativeEndpoints.REPORT_JS_LOG:
            if(args != nil){
                Log("console:: " + args!.decodeUrl()!)
            }
        case NativeEndpoints.OPEN:
            open(args!.decodeUrl()!)
        case NativeEndpoints.STORE_PICTURE:
            savePicture(args!.decodeUrl()!)
        case NativeEndpoints.CREATE_CALENDAR_EVENT:
            saveCalendarEvent(eventStr: args!.decodeUrl()!, completionHandler:{() in
                self.showConfirmationDialogue(title: "Save Complete", message: "An event has been added to your calendar.")
            })
        case NativeEndpoints.PLAY_VIDEO:
            playVideo(args!.decodeUrl()!)
        case NativeEndpoints.RESIZE:
            resize();
        case NativeEndpoints.SET_RESIZE_PROPERTIES:
            setResizeProperties(args!.decodeUrl()!)
        case NativeEndpoints.SET_EXPAND_PROPERTIES:
            setExpandProperties(args!.decodeUrl()!)
        case NativeEndpoints.CLOSE:
            self.closeButton?.removeFromSuperview()
            self.closeButton = nil
            if(state == States.RESIZED){
                closeResizedView()
            }
            else if(state == States.EXPANDED){
                closeExpandedView()
            }else if (isInterstitial){
                mraidDelegate!.close()
            }
        default:
            break
        }
    }
    
    public func setIsViewable(_ isViewable:Bool){
        setMRAIDIsViewable(isViewable)
        if(isViewable != self.isViewable){
            fireMRAIDEvent(Events.VIEWABLE_CHANGE, args:String(isViewable))
        }
        self.isViewable = isViewable
    }
    
    @objc func onCloseExpandedClicked(sender:UIButton!){
        sender.removeFromSuperview()
        closeExpandedView()
    }
    
    @objc func onCloseResizeClicked(sender:UIButton!){
        sender.removeFromSuperview()
        closeResizedView()
    }
    
    func closeExpandedView(){
        mraidDelegate!.close()
        isExpandedView = false
        setMRAIDState(States.DEFAULT)
        setMRAIDSizeChanged(to:parentVC!.view.frame.size)
    }
    
    @objc func closeResizedView(){
        mraidDelegate!.close()
        setMRAIDState(States.DEFAULT)
        setMRAIDSizeChanged(to:parentVC!.view.frame.size)
    }
    
    public func addCloseButton(to:UIView, action:Selector, showButton:Bool, position:String = "top-right"){
        //position close region
        let w = to.bounds.width
        let h = to.bounds.height
        let closeW = CGFloat(50)
        let closeH = CGFloat(50)
        
        let closeX = (position.range(of:"right") != nil) ? (w - closeW):
            (position.range(of:"center") != nil) ? ((w / 2) - (closeW / 2)):
            to.bounds.minX // must be left
        
        let closeY = (position.range(of:"bottom") != nil) ? (h - closeH):
            (position.range(of:"center") != nil) ? ((h / 2) - (closeH / 2)):
            to.bounds.minY // must be top
        
        let buttonRect = CGRect(x:closeX, y:closeY, width:closeW, height:closeH)
        
        let closeButton = UIButton(frame:buttonRect)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.backgroundColor = UIColor.init(white: 0.0, alpha: 0.0)
        to.addSubview(closeButton)
        
        if(position.range(of:"top") != nil){
            if(respectsSafeArea){
                if #available(iOS 11.0, *) {
                    let guide = to.safeAreaLayoutGuide
                    NSLayoutConstraint.activate([closeButton.topAnchor.constraint(equalToSystemSpacingBelow: guide.topAnchor, multiplier: 1.0)])
//                    NSLayoutConstraint.activate([closeButton.topAnchor.constraintEqualToSystemSpacingBelow(guide.topAnchor, multiplier: 1.0)])
                } else {
                    if let anchor = parentVC?.topLayoutGuide.bottomAnchor{
                        NSLayoutConstraint.activate([closeButton.topAnchor.constraint(equalTo: anchor)])
                    }
                }
            }else{
                NSLayoutConstraint.activate([closeButton.topAnchor.constraint(equalTo: to.topAnchor)])
            }
        }
        if(position.range(of:"bottom") != nil){
            if(respectsSafeArea){
                if #available(iOS 11.0, *) {
                    let guide = to.safeAreaLayoutGuide
                    NSLayoutConstraint.activate([closeButton.topAnchor.constraint(equalToSystemSpacingBelow: guide.topAnchor, multiplier: 1.0)])
                } else {
                    if let anchor = parentVC?.topLayoutGuide.bottomAnchor{
                        NSLayoutConstraint.activate([closeButton.topAnchor.constraint(equalTo: anchor)])
                    }
                }
            }else{
                NSLayoutConstraint.activate([closeButton.bottomAnchor.constraint(equalTo: to.bottomAnchor)])
            }
        }
        if(position.range(of:"left") != nil){
            NSLayoutConstraint.activate([closeButton.leftAnchor.constraint(equalTo: to.leftAnchor)])
        }
        if(position.range(of:"right") != nil){
            NSLayoutConstraint.activate([closeButton.rightAnchor.constraint(equalTo: to.rightAnchor)])
        }
        if(position == "center"){
            NSLayoutConstraint.activate([to.centerXAnchor.constraint(equalTo: to.centerXAnchor),
                                         to.centerYAnchor.constraint(equalTo: to.centerYAnchor)])
        }else if(position.range(of:"center") != nil){
            NSLayoutConstraint.activate([to.centerXAnchor.constraint(equalTo: to.centerXAnchor)])
        }
        
        if(showButton){ // resized views will create a close button region, but not display it as per MRAID spec
            closeButton.setTitleColor(UIColor.white, for:UIControl.State.normal)
            closeButton.setBackgroundImage(UIImage(named:"closeButtonBG", in: Bundle(identifier:"adbutler.ios.mraid.sdk"), compatibleWith:nil), for: UIControl.State.normal)
            closeButton.setTitle("X", for:UIControl.State.normal)
            closeButton.titleLabel!.textAlignment = NSTextAlignment.center
            closeButton.titleLabel!.font = UIFont.init(descriptor: UIFontDescriptor(name:"Gill Sans", size:24.0), size: 24.0)
        }
        
        self.closeButton = closeButton
        closeButton.addTarget(self, action: action, for:UIControl.Event.touchUpInside)
        
    }
    
    public func getExpandProperties() -> ExpandProperties? {
        return expandProperties;
    }
    
    /** ------------------------------------------------------------------------
     Invoke MRAID js functions
     ------------------------------------------------------------------------ */
    
    public func setMRAIDState(_ state:String){
        self.state = state
        let js = "window.mraid.setState(\"" + state + "\");"
        activeWebView.evaluateJavaScript(js, completionHandler: nil)
    }
    
    private func fireMRAIDEvent(_ event:String, args:String? = nil){
        var js = "window.mraid.fireEvent(\"" + event + "\"" + (args != nil ? ("," + args!) : "") + ");"
        if(event == Events.ERROR){
            js += "throw new Error(\(args ?? ""));"
        }
        activeWebView.evaluateJavaScript(js, completionHandler: nil)
    }
    
    private func setMRAIDSupports(_ feature:String){
        let supports = supportedFeatures.firstIndex(of:feature) != -1
        let js = "window.mraid.setSupports(\"" + feature + "\", " + String(supports) + ");"
        activeWebView.evaluateJavaScript(js, completionHandler: nil)
    }
    
    public func setMRAIDSizeChanged(to:CGSize){
        fireMRAIDEvent(Events.SIZE_CHANGE, args: "{ width:\"" + String(describing:to.width) + "\", height:\"" + String(describing:to.height) + "\"}")
    }
    
    public func setMRAIDPlacementType(_ type:String){
        if(type == PlacementTypes.INTERSTITIAL){
            isInterstitial = true
        }
        let js = "window.mraid.setPlacementType(\(type));"
        activeWebView.evaluateJavaScript(js, completionHandler: nil)
    }
    
    private func setMRAIDVersion(_ version:String){
        let js = "window.mraid.setVersion(\"\(version)\");"
        activeWebView.evaluateJavaScript(js, completionHandler: nil)
    }
    
    private func setMRAIDMaxSize(_ size:CGSize){
        let js = "window.mraid.setMaxSize({width:\(size.width), height:\(size.height)});"
        activeWebView.evaluateJavaScript(js, completionHandler: nil)
    }
    
    public func setMRAIDScreenSize(_ size:CGSize){
        let js = "window.mraid.setScreenSize({width:\(size.width), height:\(size.height)});"
        activeWebView.evaluateJavaScript(js, completionHandler: nil)
    }
    
    private func setMRAIDCurrentPosition(_ pos:CGRect){
        let js = "window.mraid.setCurrentPosition({x:\(pos.minX), y:\(pos.minY), width:\(pos.width), height:\(pos.height)});"
        activeWebView.evaluateJavaScript(js, completionHandler: nil)
    }
    
    private func setMRAIDDefaultPosition(_ pos:CGRect){
        let js = "window.mraid.setDefaultPosition({x:\(pos.minX), y:\(pos.minY), width:\(pos.width), height:\(pos.height)});"
        activeWebView.evaluateJavaScript(js, completionHandler: nil)
    }
    
    private func setMRAIDIsViewable(_ isViewable:Bool){
        let js = "window.mraid.setIsViewable(\(isViewable));"
        activeWebView.evaluateJavaScript(js, completionHandler: nil)
    }
    
    /** ------------------------------------------------------------------------
     Called By mraid
     ------------------------------------------------------------------------ */
    
    /* MRAID 2.0
     An expanded view must cover all available screen area even though the ad creative may not
     (e.g. via a transparent or opaque overlay). The expanded ad is always modal, and naturally
     the container should prevent new ads from loading during the expand state so that the user
     can complete any desired interactions with the ad creative without interruption. Other
     application-specific difficulties such as poorly built apps with multiple window objects, or timers
     that change the content z-order, must be considered by vendors when implementing the
     expand method.
     An expanded view must provide an end-user with the ability to close the expanded creative.
     These requirements are discussed further in the description of closing expandable and
     interstitial ads, below.
     */
    
    private func expand(_ url:String?){
        Log("expand")
        if(self.state == States.DEFAULT){
            switch (orientationProperties.forceOrientation){
            case Orientations.PORTRAIT:
                let value = UIInterfaceOrientation.portrait.rawValue
                UIDevice.current.setValue(value, forKey: "orientation")
                UIViewController.attemptRotationToDeviceOrientation()
            case Orientations.LANDSCAPE:
                let value = UIInterfaceOrientation.landscapeLeft.rawValue
                UIDevice.current.setValue(value, forKey: "orientation")
                UIViewController.attemptRotationToDeviceOrientation()
            default:
                break
            }
            
            mraidDelegate!.expand(url)
            if(expandProperties?.useCustomClose != true){
                addCloseButton(to:activeWebView, action:#selector(onCloseExpandedClicked), showButton:expandProperties?.useCustomClose ?? true)
            }
            // give the webview a little bit of time to resize before informing the ad of the change
            // to avoid some potential bugs
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.025) { // change 2 to desired number of seconds
                self.setMRAIDCurrentPosition(self.parentVC!.view.frame)
                self.setMRAIDSizeChanged(to:self.parentVC!.view.frame.size);
                self.setMRAIDState(States.EXPANDED)
            }
        }
    }
    
    /*    MRAID 2.0
     The open method will display an embedded browser window in the application that loads an
     external URL. On device platforms that do not allow an embedded browser, the open method
     invokes the native browser with the external URL.
     */
    private func open(_ url:String){
        Log("open - \(url)")
        if(url.range(of:"tel://") != nil){
            makePhoneCall(url)
        }
        else if(url.range(of:"sms://") != nil){
            makeSMS(url)
        }
        else if (url.range(of:"https://itunes.apple.com") != nil){
            if let url = URL(string: url), UIApplication.shared.canOpenURL(url) {
                if #available(iOS 10, *) {
                    UIApplication.shared.open(url)
                } else {
                    UIApplication.shared.openURL(url)
                }
            }
        }
        else{
            mraidDelegate!.open(url)
        }
    }
    
    /*   MRAID 2.0
     The resize method will move the state from "default" to "resized" and fire the stateChange
     event. Resize can be called multiple times by the creative. Additional calls to resize will also
     trigger the stateChanged event although the state value will remain “resized.” Calls to resize
     from an “expanded” state will trigger an error event and not change the state.
     
     Note that resize() relies on parameters that are stored in the resizeProperties
     JavaScript object. Thus the creative must set those parameters via the setResizeProperties()
     method BEFORE attempting to resize(). Calling resize() before setResizeProperties will result in
     an error
     */
    public func resize(){
        if(resizeProperties == nil){
            fireMRAIDEvent(Events.ERROR, args:"Resize() cannot be called before setResizeProperties().")
            return
        }
        if(state == States.DEFAULT || state == States.RESIZED){
            if(closeButton != nil){
                closeButton?.removeFromSuperview()
                closeButton = nil
            }
            // CHECK FOR VALID CLOSE BUTTON LOCATION..  mraid.js will also attempt this, but for redundancy, check here
            if(resizeProperties!.allowOffscreen != nil && resizeProperties!.allowOffscreen!){
                let pos = resizeProperties!.customClosePosition ?? "top-right"
                let frame = activeWebView!.frame
                var valid = true
                if(pos.range(of:"right") != nil){
                    let offscreenRight = frame.minX + CGFloat(resizeProperties!.width!) + CGFloat(resizeProperties!.offsetX!) > UIScreen.main.bounds.width
                    let offscreenLeft = frame.minX + CGFloat(resizeProperties!.width!) + CGFloat(resizeProperties!.offsetX!) < 50
                    if(offscreenLeft || offscreenRight) {
                        valid = false
                    }
                }
                if(pos.range(of:"left") != nil){
                    let offscreenLeft = frame.minX + CGFloat(resizeProperties!.offsetX!) < 0
                    let offscreenRight = frame.minX + CGFloat(resizeProperties!.offsetX!) > UIScreen.main.bounds.width - 50
                    if(offscreenLeft || offscreenRight) {
                        valid = false
                    }
                }
                if(pos.range(of:"top") != nil){
                    let offscreenTop = frame.minY + CGFloat(resizeProperties!.offsetY!) < 0
                    let offscreenBottom = frame.minY + CGFloat(resizeProperties!.offsetY!) > UIScreen.main.bounds.height - 50
                    if(offscreenTop || offscreenBottom) {
                        valid = false
                    }
                }
                if(pos.range(of:"bottom") != nil){
                    let offscreenTop = frame.minY + CGFloat(resizeProperties!.height!) + CGFloat(resizeProperties!.offsetY!) < 50
                    let offscreenBottom = frame.minY + CGFloat(resizeProperties!.height!) + CGFloat(resizeProperties!.offsetY!) > UIScreen.main.bounds.height
                    if(offscreenTop || offscreenBottom) {
                        valid = false
                    }
                }
                if(!valid){
                    fireMRAIDEvent(Events.ERROR, args:"Current resize properties would result in the close region being off screen.  Ignoring resize.")
                    return
                }
            }
            mraidDelegate!.resize(to:resizeProperties!)
            addCloseButton(to:activeWebView, action:#selector(onCloseResizeClicked), showButton:false, position:resizeProperties?.customClosePosition ?? "top-right")
            // give the webview a little bit of time to resize before informing the ad of the change
            // to avoid some potential bugs
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.025) { // change 2 to desired number of seconds
                self.setMRAIDSizeChanged(to:CGSize(width:self.resizeProperties!.width!, height:self.resizeProperties!.height!))
                self.setMRAIDState(States.RESIZED)
            }
        }else {
            setMRAIDState(States.RESIZED)
        }
    }
    
    private func setOrientationProperties(_ args:String?){
        Log("setOrientationProperties")
        do{
            if(args != nil){
                var properties:OrientationProperties? = try MRAIDUtilities.deserialize(args!)
                if(properties != nil){
                    properties!.forceOrientation = properties!.forceOrientation ?? Orientations.NONE
                    if(properties!.forceOrientation == Orientations.NONE){
                        orientationMask = orientationMaskAll
                    }
                    self.orientationProperties = properties!
                    if(isInterstitial || state == States.EXPANDED){
                        switch (orientationProperties.forceOrientation){
                        case Orientations.PORTRAIT:
                            orientationMask = [ .portrait ]
                            if(isViewable){
                                let value = UIInterfaceOrientation.portrait.rawValue
                                UIDevice.current.setValue(value, forKey: "orientation")
                                UIViewController.attemptRotationToDeviceOrientation()
                            }
                            break
                        case Orientations.LANDSCAPE:
                            orientationMask = [ .landscapeLeft ]
                            if(isViewable){
                                let value = UIInterfaceOrientation.landscapeLeft.rawValue
                                UIDevice.current.setValue(value, forKey: "orientation")
                                UIViewController.attemptRotationToDeviceOrientation()
                            }
                        default:
                            break
                        }
                    }
                }
            }else{
                //TODO handle error
            }
        }
        catch{
            // TODO error deserializing
        }
    }
    
    public func setResizeProperties(_ args:String?){
        Log("setResizeProperties")
        do{
            if(args != nil){
                let properties:ResizeProperties? = try MRAIDUtilities.deserialize(args!)
                if(properties != nil){
                    self.resizeProperties = properties!
                }
            }else{
                //TODO handle error
            }
        }
        catch{
            // TODO error deserializing
        }
    }
    
    public func setExpandProperties(_ args:String?){
        Log("setExpandProperties")
        do{
            if(args != nil){
                let properties:ExpandProperties? = try MRAIDUtilities.deserialize(args!)
                if(properties != nil){
                    let exp = ExpandProperties(
                        width:properties!.width ?? self.expandProperties?.width,
                        height:properties!.height ?? self.expandProperties?.height,
                        useCustomClose:properties!.useCustomClose ?? self.expandProperties?.useCustomClose,
                        isModal:properties!.isModal ?? self.expandProperties?.isModal)
                    
                    self.expandProperties = exp
                }
            }else{
                //TODO handle error
            }
        }
        catch{
            // TODO error deserializing
        }
    }
    
    private func playVideo(_ urlStr:String){
        mraidDelegate!.playVideo(urlStr)
    }
    
    private func makePhoneCall(_ num:String){
        let range = num.range(of:"tel://")
        if(range != nil){
            let n = num.suffix(from:range!.upperBound)
            let s = String(n)
            s.call()
        }
    }
    
    private func makeSMS(_ num:String){
        let range = num.range(of:"sms://")
        if(range != nil){
            let n = num.suffix(from:range!.upperBound)
            let s = String(n)
            s.sms()
        }
    }
    
    private func savePicture(_ urlStr:String){
        // load image
        let status = PHPhotoLibrary.authorizationStatus()
        if(status == .authorized){
            guard let url = URL(string: urlStr) else { return }
            downloadImage(url: url)
        }else{
            let bundleDict = Bundle.main.infoDictionary
            if(bundleDict?["NSPhotoLibraryUsageDescription"] != nil){
                PHPhotoLibrary.requestAuthorization({status in
                    if(status == .authorized){
                        guard let url = URL(string: urlStr) else { return }
                        self.downloadImage(url: url)
                    }
                })
            }else{
                Log("Main bundle info.plist file does not contain the key \"NSPhotoLibraryUsageDescription\".  Cannot ask user for permission.", force:true)
            }
        }
    }
    
    private func saveCalendarEvent(eventStr:String, completionHandler:@escaping ()->Void){
        do{
            let mraidEvent:MRAIDCalendarEvent? = try MRAIDUtilities.deserialize(eventStr)
            if(mraidEvent != nil){
                let status = EKEventStore.authorizationStatus(for: EKEntityType.event)
                if(status == .authorized){
                    let success = MRAIDUtilities.addCalendarItem(mraidEvent: mraidEvent!)
                    if(success){
                        completionHandler()
                    }else{
                        showErrorDialog("There was an error attempting to add a calendar event.")
                    }
                } else{
                    let bundleDict = Bundle.main.infoDictionary
                    if(bundleDict?["NSCalendarsUsageDescription"] != nil){
                        EKEventStore().requestAccess(to: EKEntityType.event, completion: {
                            (accessGranted: Bool, error: Error?) in
                            if accessGranted == true {
                                let success = MRAIDUtilities.addCalendarItem(mraidEvent: mraidEvent!)
                                if(success){
                                    completionHandler()
                                }else{
                                    self.showErrorDialog("There was an error attempting to add a calendar event.")
                                }
                            } else {
                                
                            }
                            })
                    }else{
                        Log("Main bundle info.plist file does not contain the key \"NSCalendarsUsageDescription\".  Cannot ask user for permission.", force:true)
                    }
                }
            }
        }catch MRAIDError.invalidStartDate {
            showErrorDialog("There was an error attempting to add a calendar event.")
        }catch MRAIDError.invalidEndDate {
            showErrorDialog("There was an error attempting to add a calendar event.")
        }catch {
            Log("Error deserializing calendar event.")
        }
    }
    
    /* ------------------------------------------------------------------
     Helpers
     ------------------------------------------------------------------*/
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            // we got back an error!
            let ac = UIAlertController(title: "Save error", message: error.localizedDescription, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            parentVC!.present(ac, animated: true)
        } else {
            let ac = UIAlertController(title: "Saved!", message: "An image has been added to your library.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            parentVC!.present(ac, animated: true)
        }
    }
    
    public func Log(_ msg:String, force:Bool = false){
        if(debug || force){
            NSLog("AdButler-> " + String(describing: type(of:self)) + "-> %@", msg);
        }
    }
    
    func downloadImage(url: URL) {
        getDataFromUrl(url: url) { data, response, error in
            guard let data = data, error == nil else { return }
            guard let img = UIImage(data:data) else { return }
            DispatchQueue.main.async() {
                UIImageWriteToSavedPhotosAlbum(img, self, #selector(self.image(_:didFinishSavingWithError:contextInfo:)), nil)
            }
        }
    }
    
    func getDataFromUrl(url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            completion(data, response, error)
            }.resume()
    }
    
    func getSupportedFeatures(){
        supportedFeatures.append(Features.STORE_PICTURE)
        supportedFeatures.append(Features.CALENDAR)
        supportedFeatures.append(Features.INLINE_VIDEO)
        if(UIApplication.shared.canOpenURL(URL(string:"tel:+11111")!)){
            supportedFeatures.append(Features.TEL)
            supportedFeatures.append(Features.SMS)
        }
    }
    
    func showErrorDialog(_ msg:String){
        let alert = UIAlertController(title: "Notice", message: msg, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title:"Close", style: .default, handler:nil))
        parentVC!.present(alert, animated:true)
    }
    
    func showConfirmationDialogue(title:String, message:String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title:"Close", style: .default, handler:nil))
        parentVC!.present(alert, animated:true)
    }
    
    func setRespectsSafeArea(_ val:Bool){
        respectsSafeArea = val
    }
}
