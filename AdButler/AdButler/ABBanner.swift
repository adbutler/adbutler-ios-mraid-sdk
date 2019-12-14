import Foundation

@objc public class ABBanner: NSObject {
    private var imageView:UIView? = nil
    private var viewController:UIViewController? = nil
    private var placementRequestConfig:PlacementRequestConfig? = nil
    private var placement:Placement?
    private var refreshes:Int = 0
    private var timer:Timer?
    private var parentViewController:UIViewController?
    private var position:String = Positions.BOTTOM_CENTER
    private var refreshToContainer:Bool = false
    
    deinit {
        timer?.invalidate()
    }

    @objc public init(placement:Placement, container:UIView, respectSafeAreaLayoutGuide:Bool){
        super.init()
        self.placement = placement
        self.refreshToContainer = true
        if(placement.imageUrl != nil){
            if(placement.refreshTime != nil){
                let interval = Double(placement.refreshTime!)
                timer = Timer.scheduledTimer(timeInterval: interval!, target: self, selector: #selector(refresh), userInfo: nil, repeats: true)
            }
            
            placement.getImageView { imageView in
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                self.imageView = imageView
                container.addSubview(imageView)
                imageView.frame = CGRect(x:0, y:0, width:container.frame.width, height:container.frame.height)
                NSLayoutConstraint.activate([
                    imageView.heightAnchor.constraint(equalTo:container.heightAnchor),
                    imageView.widthAnchor.constraint(equalTo:container.widthAnchor)
                    ])
                placement.recordImpression()
            }
        }else{
            NSLog("Error - HTML Banners cannot be initialized with a container view.  Please use the init(placement:Placement, parentViewController:UIViewController, position:String, respectSafeAreaLayoutGuide:Bool = false) constructor")
        }
    }
    
    @objc public convenience init(placement:Placement, container:UIView, respectSafeAreaLayoutGuide:Bool, placementRequestConfig:PlacementRequestConfig){
        self.init(placement: placement, container: container, respectSafeAreaLayoutGuide: respectSafeAreaLayoutGuide)
        self.placementRequestConfig = placementRequestConfig
    }
    
    @objc public init(placement:Placement, parentViewController:UIViewController, position:String, respectSafeAreaLayoutGuide:Bool){
        super.init()
        self.position = position
        self.parentViewController = parentViewController
        self.placement = placement
        if(placement.body != nil){
            let banner = ABMRAIDBanner()
            self.viewController = banner
            banner.initialize(placement:placement, parentViewController:parentViewController, position:position, respectSafeArea:respectSafeAreaLayoutGuide)
            placement.recordImpression()
        }else if(placement.imageUrl != nil){
            if(placement.refreshTime != nil){
                let interval = Double(placement.refreshTime!)
                timer = Timer.scheduledTimer(timeInterval: interval!, target: self, selector: #selector(refresh), userInfo: nil, repeats: true)
            }
            placement.getImageView { imageView in
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                parentViewController.view.addSubview(imageView)
                self.imageView = imageView
                imageView.frame = self.getFrameFromPlacement()
                placement.recordImpression()
            }
        }
    }
    
    @objc public convenience init(placement:Placement, parentViewController:UIViewController, position:String, respectSafeAreaLayoutGuide:Bool, placementRequestConfig:PlacementRequestConfig){
        self.init(placement:placement, parentViewController: parentViewController, position:position, respectSafeAreaLayoutGuide: respectSafeAreaLayoutGuide)
        self.placementRequestConfig = placementRequestConfig
    }
    
    private func getFrameFromPlacement()->CGRect{
        var x:CGFloat = 0
        var y:CGFloat = 0
        let parentRect = self.parentViewController!.view.bounds
        if(self.position.range(of:"top") != nil){
            y = 0
        }
        if(self.position.range(of:"bottom") != nil){
            y = parentRect.height - CGFloat(self.placement!.height)
        }
        if(self.position.range(of:"center") != nil){
            if(self.position.range(of:"left") == nil && self.position.range(of:"right") == nil){
                x = (parentRect.width / 2) - CGFloat((self.placement!.width / 2))
            }
            if(self.position.range(of:"top") == nil && self.position.range(of:"bottom") == nil){
                y = (parentRect.height / 2) - CGFloat((self.placement!.height / 2))
            }
        }
        
        if(self.placement!.refreshTime != nil){
            if(self.placementRequestConfig == nil){
                NSLog("AdButler", "This banner will not refresh unless you construct it with a PlacementRequestConfig object");
            } else if (self.timer != nil && !self.timer!.isValid) {
                let interval = Double(self.placement!.refreshTime!)
                timer = Timer.scheduledTimer(timeInterval: interval!, target: self, selector: #selector(refresh), userInfo: nil, repeats: true)
            }
        }
        
        if(self.position.range(of:"left") != nil){
            x = 0
        }
        if(self.position.range(of:"right") != nil){
            x = parentRect.width - CGFloat(self.placement!.width)
        }
        return CGRect(x:x, y:y, width:CGFloat(self.placement!.width), height:CGFloat(self.placement!.height));
    }
    
    @objc public func destroy(){
        self.timer?.invalidate()
        if(self.imageView != nil) {
            self.imageView!.removeFromSuperview()
        }
        if(self.viewController != nil) {
            self.viewController!.removeFromParent()
            self.viewController!.view.removeFromSuperview()
        }
    }
    
    @objc func refresh() {
        if(self.placementRequestConfig == nil){
            NSLog("AdButler", "You must construct a ABBanner with a PlacementRequestConfig in order to support zone refreshing.")
            return;
        }
        if(self.placement?.refreshUrl == nil){
            self.timer?.invalidate()
            return
        }
        if(self.placement != nil){
            AdButler.refreshPlacement(with:self.placement!, config:self.placementRequestConfig!) { response in
                switch response {
                case .success(_ , let placements):
                    do {
                        guard placements.count == 1 else {
                            return
                        }
                        guard placements[0].isValid else {
                            return
                        }
                        self.placement = placements[0]
                        try self.placement!.getImageView { imageView in
                            if(self.imageView == nil){
                                self.destroy()
                                return
                            }
                            let view = self.imageView!.superview
                            if(view == nil || imageView == nil){
                                self.destroy()
                                return
                            }else{
                                self.imageView!.removeFromSuperview()
                                self.imageView = imageView
                                view?.addSubview(self.imageView!)
                                self.placement!.recordImpression()
                                if(self.refreshToContainer){
                                    self.imageView!.frame = CGRect(x:0, y:0, width:view!.frame.width, height:view!.frame.height)
                                    NSLayoutConstraint.activate([
                                        self.imageView!.heightAnchor.constraint(equalTo:view!.heightAnchor),
                                        self.imageView!.widthAnchor.constraint(equalTo:view!.widthAnchor)
                                        ])
                                }else{
                                    self.imageView!.frame = self.getFrameFromPlacement()
                                }
                            }
                        }
                    } catch {
                        // Something is missing in our banner.  (Maybe reference to it was lost)
                        self.destroy()
                    }
                case .badRequest(let statusCode, let responseBody):
                    return
                case .invalidJson(let responseBody):
                    return
                case .requestError( _):
                    return
                }
            }
        }
    }
}
