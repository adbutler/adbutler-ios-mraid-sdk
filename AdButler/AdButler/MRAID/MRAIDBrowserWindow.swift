//
//  MRAIDBrowserWindow.swift
//  AdButler
//

//  Copyright © 2018 AdButler, Inc. All rights reserved.
//

import Foundation
import WebKit
import UIKit
public class MRAIDBrowserWindow : UIViewController, WKUIDelegate, WKNavigationDelegate {
    private static let btnWidth = CGFloat(50)
    private static let btnHeight = CGFloat(50)
    private static let navHeight = btnHeight
    
//    private let navigationRect = CGRect(x:0, y:UIApplication.shared.isStatusBarHidden ? 0 : UIApplication.shared.statusBarFrame.height, width:UIScreen.main.bounds.width, height:navHeight)
//    private let webViewRect = CGRect(x:0, y:navHeight + (UIApplication.shared.isStatusBarHidden ? 0 : UIApplication.shared.statusBarFrame.height), width:UIScreen.main.bounds.width, height:UIScreen.main.bounds.height - navHeight)
    private var webView:WKWebView?
    private var navigationView:UIView?
    
    private var btnClose:UIButton?
    private var btnForward:UIButton?
    private var btnBack:UIButton?
    private var btnReload:UIButton?
    private static var dividerImage = UIImage(named: "navigationDivider", in: Bundle(identifier:"adbutler.ios.mraid.sdk"), compatibleWith:nil)
    private var dividerLeft = UIImageView(image:dividerImage)
    private var dividerRight = UIImageView(image:dividerImage)
    
    private var btnRect = CGRect(x:0, y:0, width:btnWidth, height:btnHeight)
    private var dividerRect = CGRect(x:0, y:0, width:4.0, height:btnHeight)
    private var onCloseDelegate:()->Void = {}
    
    
    public func initialize(){
        webView = WKWebView()
        webView!.isOpaque = true
        webView!.isUserInteractionEnabled = true
        //webView!.frame = webViewRect
        webView!.navigationDelegate = self
        view.backgroundColor = UIColor.white
        view.isUserInteractionEnabled = true
        navigationView = UIView()
        navigationView!.isOpaque = true
        navigationView!.isUserInteractionEnabled = true
        navigationView!.backgroundColor = UIColor(red: 238.0/255.0, green: 238.0/255.0, blue: 238.0/255.0, alpha: 1)
        view.addSubview(navigationView!)
        view.addSubview(webView!)
        addFrameConstraints()
        addNavigationButtons()
    }
    
    public override var prefersStatusBarHidden: Bool {
        get {
            return false
        }
    }
    
    public func loadUrl(_ url:String){
        let urlObj = URL(string: url)
        webView!.load(URLRequest(url:urlObj!))
    }
    
    public func onClose(perform:@escaping()->Void){
        onCloseDelegate = perform
    }
    
    public func webView(_ webView: WKWebView,
                        decidePolicyFor navigationAction: WKNavigationAction,
                        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let url = navigationAction.request.url?.absoluteString
        if (url?.range(of:"https://itunes.apple.com") != nil){
            if let url = URL(string: url!), UIApplication.shared.canOpenURL(url) {
                if #available(iOS 10, *) {
                    UIApplication.shared.open(url)
                } else {
                    UIApplication.shared.openURL(url)
                }
            }
        }
        decisionHandler(.allow)
        return
    }
    
    private func addNavigationButtons(){
        btnClose = UIButton()
        btnClose!.addTarget(self, action: #selector(onCloseClicked), for:UIControl.Event.touchUpInside)
        btnForward = UIButton()
        btnForward!.addTarget(self, action: #selector(onForwardClicked), for:UIControl.Event.touchUpInside)
        btnBack = UIButton()
        btnBack!.addTarget(self, action: #selector(onBackClicked), for:UIControl.Event.touchUpInside)
        btnReload = UIButton()
        btnReload!.addTarget(self, action: #selector(onReloadClicked), for:UIControl.Event.touchUpInside)
        
        btnClose?.translatesAutoresizingMaskIntoConstraints = false
        btnReload?.translatesAutoresizingMaskIntoConstraints = false
        btnForward?.translatesAutoresizingMaskIntoConstraints = false
        btnBack?.translatesAutoresizingMaskIntoConstraints = false
        dividerLeft.translatesAutoresizingMaskIntoConstraints = false
        dividerRight.translatesAutoresizingMaskIntoConstraints = false
        
        btnForward!.setImage(UIImage(named: "navigationForward", in: Bundle(identifier:"adbutler.ios.mraid.sdk"), compatibleWith:nil), for:UIControl.State.normal)
        btnBack!.setImage(UIImage(named: "navigationBack", in: Bundle(identifier:"adbutler.ios.mraid.sdk"), compatibleWith:nil), for:UIControl.State.normal)
        btnReload!.setImage(UIImage(named: "navigationReload", in: Bundle(identifier:"adbutler.ios.mraid.sdk"), compatibleWith:nil), for:UIControl.State.normal)
        btnClose!.setImage(UIImage(named: "navigationClose", in: Bundle(identifier:"adbutler.ios.mraid.sdk"), compatibleWith:nil), for:UIControl.State.normal)
        
        navigationView!.addSubview(btnClose!)
        navigationView!.addSubview(btnForward!)
        navigationView!.addSubview(dividerLeft)
        navigationView!.addSubview(btnBack!)
        navigationView!.addSubview(dividerRight)
        navigationView!.addSubview(btnReload!)

        addButtonConstraints()
    }
    
    @objc public func onCloseClicked(){
        // cleanup.  better to be overkill here than risk memory leaks
        navigationView?.removeFromSuperview()
        navigationView = nil
        webView?.removeFromSuperview()
        webView = nil
        view.removeFromSuperview()
        view = nil
        removeFromParent()
        onCloseDelegate()
    }
    
    @objc public func onBackClicked(){
        webView!.goBack()
    }
    
    @objc public func onReloadClicked(){
        webView!.reload()
    }
    
    @objc public func onForwardClicked(){
        webView!.goForward()
    }
    
    private func addFrameConstraints(){
        if #available(iOS 11.0, *) {
            navigationView?.translatesAutoresizingMaskIntoConstraints = false
            webView?.translatesAutoresizingMaskIntoConstraints = false
            view!.addConstraint(NSLayoutConstraint(item:navigationView!, attribute: .top, relatedBy: .equal, toItem: view!.safeAreaLayoutGuide, attribute: .top, multiplier:1.0, constant:0))
            view!.addConstraint(NSLayoutConstraint(item:navigationView!, attribute: .left, relatedBy: .equal, toItem: view!.safeAreaLayoutGuide, attribute: .left, multiplier:1.0, constant:0))
            view!.addConstraint(NSLayoutConstraint(item:navigationView!, attribute: .right, relatedBy: .equal, toItem: view!.safeAreaLayoutGuide, attribute: .right, multiplier:1.0, constant:0))
            NSLayoutConstraint.activate([navigationView!.heightAnchor.constraint(equalToConstant: MRAIDBrowserWindow.navHeight)])
            
            view!.addConstraint(NSLayoutConstraint(item:webView!, attribute: .top, relatedBy: .equal, toItem: navigationView!, attribute: .bottom, multiplier:1.0, constant:0))
            view!.addConstraint(NSLayoutConstraint(item:webView!, attribute: .left, relatedBy: .equal, toItem: view!.safeAreaLayoutGuide, attribute: .left, multiplier:1.0, constant:0))
            view!.addConstraint(NSLayoutConstraint(item:webView!, attribute: .right, relatedBy: .equal, toItem: view!.safeAreaLayoutGuide, attribute: .right, multiplier:1.0, constant:0))
            view!.addConstraint(NSLayoutConstraint(item:webView!, attribute: .bottom, relatedBy: .equal, toItem: view!.safeAreaLayoutGuide, attribute: .bottom, multiplier:1.0, constant:0))
        }else{
            setOldIOSFrames()
        }
    }
    
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        if #available(iOS 11.0, *){
            // constraints shoudl handle it
        }else{
            setOldIOSFrames(true)
        }
        
    }
    
    private func setOldIOSFrames(_ invert:Bool = false){
        if(invert){
            let navigationRect = CGRect(x:0, y:UIApplication.shared.isStatusBarHidden ? 0 : UIApplication.shared.statusBarFrame.height, width:UIScreen.main.bounds.height, height:MRAIDBrowserWindow.navHeight)
            let webViewRect = CGRect(x:0, y:MRAIDBrowserWindow.navHeight + (UIApplication.shared.isStatusBarHidden ? 0 : UIApplication.shared.statusBarFrame.height), width:UIScreen.main.bounds.height, height:UIScreen.main.bounds.width - MRAIDBrowserWindow.navHeight)
            navigationView!.frame = navigationRect
            webView!.frame = webViewRect
        }else{
            let navigationRect = CGRect(x:0, y:UIApplication.shared.isStatusBarHidden ? 0 : UIApplication.shared.statusBarFrame.height, width:UIScreen.main.bounds.width, height:MRAIDBrowserWindow.navHeight)
            let webViewRect = CGRect(x:0, y:MRAIDBrowserWindow.navHeight + (UIApplication.shared.isStatusBarHidden ? 0 : UIApplication.shared.statusBarFrame.height), width:UIScreen.main.bounds.width, height:UIScreen.main.bounds.height - MRAIDBrowserWindow.navHeight)
            navigationView!.frame = navigationRect
            webView!.frame = webViewRect
        }
    }
    
    private func addButtonConstraints(){
        // back
        navigationView!.addConstraint(NSLayoutConstraint(item:navigationView!, attribute: .left, relatedBy: .equal, toItem: btnBack!, attribute: .left, multiplier:1.0, constant:0))
        navigationView!.addConstraint(NSLayoutConstraint(item:navigationView!, attribute: .centerY, relatedBy: .equal, toItem: btnBack!, attribute: .centerY, multiplier:1.0, constant:0))
        btnBack!.addConstraint(NSLayoutConstraint(item:btnBack!, attribute: .width, relatedBy:.equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant:MRAIDBrowserWindow.btnWidth))
        btnBack!.addConstraint(NSLayoutConstraint(item:btnBack!, attribute: .height, relatedBy:.equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant:MRAIDBrowserWindow.btnHeight))
        // dividerleft
        navigationView!.addConstraint(NSLayoutConstraint(item:dividerLeft, attribute: .left, relatedBy: .equal, toItem: btnBack!, attribute: .right, multiplier:1.0, constant:0))
        navigationView!.addConstraint(NSLayoutConstraint(item:navigationView!, attribute: .centerY, relatedBy: .equal, toItem: dividerLeft, attribute: .centerY, multiplier:1.0, constant:0))
        dividerLeft.addConstraint(NSLayoutConstraint(item:dividerLeft, attribute: .width, relatedBy:.equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant:2.0))
        dividerLeft.addConstraint(NSLayoutConstraint(item:dividerLeft, attribute: .height, relatedBy:.equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant:MRAIDBrowserWindow.btnHeight * 0.75))
        // reload
        navigationView!.addConstraint(NSLayoutConstraint(item:btnReload!, attribute: .left, relatedBy: .equal, toItem: dividerLeft, attribute: .right, multiplier:1.0, constant:0))
        navigationView!.addConstraint(NSLayoutConstraint(item:navigationView!, attribute: .centerY, relatedBy: .equal, toItem: btnReload!, attribute: .centerY, multiplier:1.0, constant:0))
        btnReload!.addConstraint(NSLayoutConstraint(item:btnReload!, attribute: .width, relatedBy:.equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant:MRAIDBrowserWindow.btnWidth))
        btnReload!.addConstraint(NSLayoutConstraint(item:btnReload!, attribute: .height, relatedBy:.equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant:MRAIDBrowserWindow.btnHeight))
        // dividerRight
        navigationView!.addConstraint(NSLayoutConstraint(item:dividerRight, attribute: .left, relatedBy: .equal, toItem: btnReload!, attribute: .right, multiplier:1.0, constant:0))
        navigationView!.addConstraint(NSLayoutConstraint(item:navigationView!, attribute: .centerY, relatedBy: .equal, toItem: dividerRight, attribute: .centerY, multiplier:1.0, constant:0))
        dividerRight.addConstraint(NSLayoutConstraint(item:dividerRight, attribute: .width, relatedBy:.equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant:2.0))
        dividerRight.addConstraint(NSLayoutConstraint(item:dividerRight, attribute: .height, relatedBy:.equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant:MRAIDBrowserWindow.btnHeight * 0.75))
        // forward
        navigationView!.addConstraint(NSLayoutConstraint(item:btnForward!, attribute: .left, relatedBy: .equal, toItem: dividerRight, attribute: .right, multiplier:1.0, constant:0))
        navigationView!.addConstraint(NSLayoutConstraint(item:navigationView!, attribute: .centerY, relatedBy: .equal, toItem: btnForward!, attribute: .centerY, multiplier:1.0, constant:0))
        btnForward!.addConstraint(NSLayoutConstraint(item:btnForward!, attribute: .width, relatedBy:.equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant:MRAIDBrowserWindow.btnWidth))
        btnForward!.addConstraint(NSLayoutConstraint(item:btnForward!, attribute: .height, relatedBy:.equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant:MRAIDBrowserWindow.btnHeight))
        // close
        navigationView!.addConstraint(NSLayoutConstraint(item:navigationView!, attribute: .right, relatedBy: .equal, toItem: btnClose!, attribute: .right, multiplier:1.0, constant:0))
        navigationView!.addConstraint(NSLayoutConstraint(item:navigationView!, attribute: .centerY, relatedBy: .equal, toItem: btnClose!, attribute: .centerY, multiplier:1.0, constant:0))
        btnClose!.addConstraint(NSLayoutConstraint(item:btnClose!, attribute: .width, relatedBy:.equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant:MRAIDBrowserWindow.btnWidth))
        btnClose!.addConstraint(NSLayoutConstraint(item:btnClose!, attribute: .height, relatedBy:.equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant:MRAIDBrowserWindow.btnHeight))
    }
    
}
