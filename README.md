
# adbutler-ios-mraid-sdk v2.0 - end user

The AdButler iOS SDK allows you to insert AdButler ads into your app.  This includes Banners, Interstitials and VAST/VPAID Video ads.

MRAID 2.0 is supported for Banners and Interstitials.

Requirements:
● iOS 10.1+
● Xcode 11+
● Swift 5

## Installation

### CocoaPods

A cocoapod will be available soon.

### Manually

Installation of the adbutler-ios-mraid-sdk can be done manually by building and copying the framework into your project.

## Usage

### Setup

If you plan to use advanced ad types such as MRIAD, your app will need permissions for certain features such as:

- Telephony (Send SMS)
- Photo Library (Save images to gallery)
- Calendar Access (Create reminders)

You will also need to alow Arbitrary Loads for certain resources.

In your `info.plist` add:

`App Transport Security Settings > Allow Arbitrary Loads > YES`

### Banners

Banners will be displayed immediately once they are returned from AdButler’s ad server.  
The response functions are included in a closure passed to the placement request.

● Creating a banner with ABBanner(placement, parentViewController, position)

- placement (currently, only one placement should be returned from AdButler, but in the future a list may be returned.  For now, only placement[0] will ever be used.
- parentViewController (This is the containing controller that should house the banner.  Typically this will be the view controller doing the banner request)
- position (A string constant noting where the banner should appear on screen.  Positions values can be found in AdButler.MRAIDConstants)

Banners should be destroyed when you want to get a new one, or just when you want it off screen.

The ABBanner.destroy() instance method will remove the banner from your view.  

#### Retrieving a banner

Width and height are optional here.  Most of the time the width and height will come from the zone in your AdButler configuration but if that is not set, you may want to set a fallback here.

    let config = PlacementRequestConfig(accountId: 50088, zoneId: 354134, width:320, height:50, customExtras:nil)
        AdButler.requestPlacement(with: config) { response in
            switch response {
            case .success(_ , let placements):
                guard placements.count == 1 else {
                    // error
                    return
                }
                guard placements[0].isValid else {
                    // error
                    return
                }
                self.banner?.destroy()
                self.banner = ABBanner(placement:placements[0], parentViewController:self, position:self.Positions.BOTTOM_CENTER, respectSafeAreaLayoutGuide:false, placementRequestConfig:config)
            case .badRequest(let statusCode, let responseBody):
                return
            case .invalidJson(let responseBody):
                return
            case .requestError(let error):
                return
            }
        }

You can also pass a container `UIView` to `ABBanner()` instead of `position` and the ad will take on the size and location of the container.

### Interstitials

Your view controller  will need to implement the ABInterstitialDelegate interface to retrieve event information.

These methods are:

    func interstitialReady(_ interstitial: ABInterstitial) {}
    
    func interstitialFailedToLoad(_ interstitial: ABInterstitial) {}
    
    func interstitialClosed(_ interstitial: ABInterstitial) {}
    
    func interstitialStartLoad(_ interstitial: ABInterstitial) {}

#### Retrieving an interstitial
  
    let config = PlacementRequestConfig(accountId: 50088, zoneId: 354135, width:nil, height:nil, customExtras:nil)
        AdButler.requestPlacement(with: config) { response in
            switch response {
            case .success(_ , let placements):
                guard placements.count == 1 else {
                    return  // interstitials should currently only return a single ad
                }
                guard placements[0].isValid else {
                    return
                }
                if(placements[0].body != nil && placements[0].body != ""){
                    self.interstitial = ABInterstitial(placement:placements[0], parentViewController:self, delegate:self, respectSafeAreaLayoutGuide:true)
                }
            default:
                return
            }
        }

● Creating an interstitial with ABInterstitial(placement, parentViewController, delegate, respectSafeAreaLayoutGuide)

- placement (as with banners, currently only one placement will be returned from AdButler)
- parentViewController (The view controller which will contain the interstitial, typically the same controller that retrieves the interstitial placement)
- delegate (A class that implements the ABInterstitialDelegate interface.  Typically the view controller which retrieves the interstitial)
- respectSafeAreaLayoutGuide (Some apps may choose to have their layout take into account the safe area layout guide in order to have the status bar showing.  If your app does this, then this setting will tell the interstitial to do the same)

Once retrieved, the interstitialReady function will be called.  After this point you can display the interstitial at any time with:

    interstitial.display();

The interstitial can only been displayed once, after which you must retrieve another one.

### VAST Video

A VAST video ad requires a delegate (`ABVASTDelegate`) to listen for VAST events.

The delegate functions include:

    func onMute() {}
    
    func onUnmute() {}
    
    func onPause() {}
    
    func onResume() {}
    
    func onRewind() {}
    
    func onSkip() {}
    
    func onPlayerExpand() {}
    
    func onPlayerCollapse() {}
    
    func onNotUsed() {}
    
    func onLoaded() {}
    
    func onStart() {}
    
    func onFirstQuartile() {}
    
    func onMidpoint() {}
    
    func onThirdQuartile() {}
    
    func onComplete() {}
    
    func onCloseLinear() {}
    
    func onBrowserOpening(){}
    
    func onBrowserClosing(){}
    
    func onReady(){}
    
    func onError(){}

VAST ads must be preloaded, similarly to how interstitials work.  After the ad is loaded and prepared, the `onReady()` function will be called.  You will notice that the `play()` and `pause()` functions will be called first.  This is because the web view, in which the video will be played is loaded off screen, to make a smoother transition to the ad.

After the `onReady()` function is called, you can call the `display()` function on the VAST object to display the ad.

The order of events are as follows:

- Create a `ABVASTVideo` object

    ```vast = ABVASTVideo()```

- Call `initialize()` on the `ABVASTVideo` object, providing your delegate and optionally, an orientation mask (if your ad is to be portrait or landscape only).  In this example below, our calling class implements `ABVASTDelegate`

    ```vast.initialize(accountID: accountID, zoneID:zoneID, publisherID:publisherID, delegate:self, orientationMask:nil)```

- Preload the VAST Video ad, providing the parent view that will house a temporary `WKWebView`, which will be used to load the ad.  *(Use your currently visible view.  The web view will not have any size and will not be seen)*

    ```vast.preload(container:self.view)```

- If the ad loads sucessfully, the `onReady()` event will be called on your `ABVASTDelegate`.  At this point, you can display the ad.

    ```vast.display()```

If you try to display the ad before it is ready, nothing will happen.

You will need to do this process each time you want an ad to be displayed, so that your impressions are counted correctly.

### Sample Projects

Included is an SDK Tester app you can use to see an example of implementation, as well as test your AdButler ads in the SDK.

#### License

This SDK is released under the Apache 2.0 license. See LICENSE for more information.
