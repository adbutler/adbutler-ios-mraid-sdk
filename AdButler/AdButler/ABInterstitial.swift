import Foundation

public class ABInterstitial: NSObject {
    private var mraidInterstitial:ABMRAIDInterstitial?
    private var interstitial:ABInterstitialView?
    private var parentViewController:UIViewController?
    public init(placement:Placement, parentViewController:UIViewController?, delegate:ABInterstitialDelegate, respectSafeAreaLayoutGuide:Bool = false, closeTimer:Int? = nil){
        super.init()
        self.parentViewController = parentViewController
        if(placement.body != nil){
            if(placement.body!.range(of:"mraid.js") != nil){
                mraidInterstitial = ABMRAIDInterstitial()
                mraidInterstitial!.initialize(placement:placement, parentViewController:parentViewController!, interstitial:self)
                mraidInterstitial!.delegate = delegate
                placement.recordImpression()
            }else{
                interstitial = ABInterstitialView()
                interstitial!.delegate = delegate
                interstitial!.loadHTMLInterstitial(placement:placement, interstitial:self, closeTime:(closeTimer != nil) ? closeTimer! : ABInterstitialView.DEFAULT_CLOSE_TIMER)
                placement.recordImpression()
            }
        }else if(placement.imageUrl != nil){
            interstitial = ABInterstitialView()
            interstitial!.delegate = delegate
            interstitial!.loadImageInterstitial(imageURL:placement.imageUrl!, interstitial:self, closeTime:(closeTimer != nil) ? closeTimer! : ABInterstitialView.DEFAULT_CLOSE_TIMER)
            placement.recordImpression()
        }
    }
    
    public func display(_ explicitParent:UIViewController? = nil){
        if(mraidInterstitial != nil){
            mraidInterstitial!.display()
        }else if(interstitial != nil){
            if(explicitParent != nil){
                interstitial!.display(explicitParent!)
            }else if(parentViewController != nil){
                interstitial!.display(parentViewController!)
            }else{
                // error
            }
        }
    }
}
