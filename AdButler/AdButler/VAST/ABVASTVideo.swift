import Foundation
import WebKit

public class ABVASTVideo : NSObject, WKUIDelegate, WKNavigationDelegate {
    
    private var rect:CGRect?
    private var webView:WKWebView?
    private var containerView:UIView?
    private var zoneID:Int!
    private var accountID:Int!
    private var publisherID:Int!
    private var poster:String!
    private var sources:[Source]?
    private var vastDelegate:ABVASTDelegate?
    private var videoPlayer:ABVideoPlayer!
    private var orientationMask:UIInterfaceOrientationMask = [.portrait, .landscapeLeft, .landscapeRight]
    internal var endCardCompanion:ABVASTCompanion? = nil
    private var ready:Bool = false
    internal var closeButtonRequired:Bool = false
    internal var postMessageHandler:ABPostMessageHandler!
    
    private let baseURL = "https://servedbyadbutler.com"
    
    struct Source {
        public var source:String!
        public var type:String!
    }
    
    public func initialize(accountID:Int, zoneID:Int, publisherID:Int, delegate:ABVASTDelegate?, orientationMask:UIInterfaceOrientationMask? = nil, poster:String? = ""){
        self.zoneID = zoneID
        self.accountID = accountID
        self.publisherID = publisherID
        self.poster = poster
        self.vastDelegate = delegate
        self.postMessageHandler = ABPostMessageHandler()
        self.postMessageHandler.initialize(vast:self)
        if(orientationMask != nil){
            self.orientationMask = orientationMask!
        }
    }
    
    public func initialize(webView:UIView, accountID:Int, zoneID:Int, publisherID:Int, delegate:ABVASTDelegate?, orientationMask:UIInterfaceOrientationMask? = nil, poster:String? = ""){
        self.containerView = webView
        self.zoneID = zoneID
        self.accountID = accountID
        self.publisherID = publisherID
        self.poster = poster
        self.vastDelegate = delegate
        self.postMessageHandler = ABPostMessageHandler()
        self.postMessageHandler.initialize(vast:self)
        if(orientationMask != nil){
            self.orientationMask = orientationMask!
        }
    }
    
    public func addSource(source:String, type:String){
        if(sources == nil){
            sources = Array()
        }
        sources!.append(Source(source:source, type:type))
    }
    
    private func getVideoJSMarkup() -> String {
        var str = """
            <html>
            <head>
                <meta name="viewport" content="initial-scale=1.0" />
                <link href="https://vjs.zencdn.net/4.12/video-js.css" rel="stylesheet">
                <script src="https://vjs.zencdn.net/4.12/video.js"></script>
                <link href="\(baseURL)/videojs-vast-vpaid/bin/videojs.vast.vpaid.min.css?v=7" rel="stylesheet">
                <script src="\(baseURL)/videojs-vast-vpaid/bin/videojs_4.vast.vpaid.js?v=18"></script>
            </head>
            <body style="margin:0px; background-color:black">
            <video id="av_video" class="video-js vjs-default-skin"
        """
        str += "controls preload=\"auto\" width=\"100%\" height=\"100%\" playsinline autoplay "
        if(self.poster != ""){
            str += "poster=\"\(self.poster!)\" "
        }
        str += "data-setup='{ "
        str += "\"plugins\": { "
        str += "\"vastClient\": { "
        str += "\"adTagUrl\": \"\(baseURL)/vast.spark?setID=\(self.zoneID!)&ID=\(self.accountID!)&pid=\(self.publisherID!)\", "
        str += "\"adCancelTimeout\": 5000, "
        str += "\"adsEnabled\": true "
        str += "} "
        str += "} "
        str += "}'> "
        if(sources != nil){
            for s in sources! {
                str += "<source src=\"\(s.source!)\" type='\(s.type!)'/>"
            }
        }else{
            str += "<source src=\"\(baseURL)/assets/blank.mp4\" type='video/mp4'/>"
        }
        str += """
        <p class="vjs-no-js">
        To view this video please enable JavaScript, and consider upgrading to a web browser that
        <a href="https://videojs.com/html5-video-support/" target="_blank">supports HTML5 video</a>
        </p>
        </video>
        </body>
        </html>
        """
        return str
    }
    
    public func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        // Capture window.open (clickthroughs) and redirect
        //webView.load(navigationAction.request)
        if(navigationAction.request.url != nil) {
            videoPlayer.requestURLFromParent(_url: navigationAction.request.url!.absoluteString)
        }
    
        return nil
    }
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        NSLog("Webview did finish")
    }
    
    public func preload(container:UIView){
        Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(timeout), userInfo: nil, repeats: false)
        let config = WKWebViewConfiguration()
        let contentController = WKUserContentController()
        contentController.add(self.postMessageHandler, name: "vastPlayerMessageHandler")
        
        config.allowsInlineMediaPlayback = true
        config.userContentController = contentController
        config.mediaTypesRequiringUserActionForPlayback = WKAudiovisualMediaTypes.init(rawValue: 0)
        
        webView = WKWebView(frame:CGRect(x:0, y:0, width:0, height:0), configuration: config)
        webView!.navigationDelegate = self
        webView!.uiDelegate = self
        webView!.isUserInteractionEnabled = true
        container.addSubview(webView!)
        
        let body = self.getVideoJSMarkup()
        webView!.loadHTMLString(body, baseURL:URL(string:"https://servedbyadbutler.com/"))
    }

    
    @objc func timeout(){
        if(!self.ready){
            self.webView?.removeFromSuperview()
            self.webView = nil
            self.vastDelegate?.onError()
        }
    }
    
    public func display(){
        if(!self.ready){
            return
        }
        self.webView!.removeFromSuperview()
        videoPlayer = ABVideoPlayer()
        videoPlayer.addCloseButtonToVideo = self.closeButtonRequired
        self.videoPlayer.setOrientationMask(self.orientationMask)
        let previousRootController = UIApplication.shared.delegate?.window??.rootViewController
        if(containerView === nil) {
            MRAIDUtilities.setRootController(videoPlayer)
            videoPlayer.playPreloadedVideo(self.webView!, container:nil, onClose: {() in
                MRAIDUtilities.setRootController(previousRootController!)
                self.videoPlayer = nil
            })
        }else {
            containerView!.addSubview(videoPlayer.view)
            videoPlayer.playPreloadedVideo(self.webView!, container:containerView!, onClose: {() in
                self.videoPlayer = nil
            })
        }
        self.webView = nil
    }
    
    
//    public func display(){
//        if(!self.ready){
//            return
//        }
//        videoPlayer = ABVideoPlayer()
//        videoPlayer.addCloseButtonToVideo = self.closeButtonRequired
//        self.videoPlayer.setOrientationMask(self.orientationMask)
//        videoPlayer.playPreloadedVideo(self.webView!, onClose: {() in
//            self.videoPlayer = nil
//        })
//        self.webView = nil
//    }
       
    public func webView(_ webView: WKWebView,
                        decidePolicyFor navigationAction: WKNavigationAction,
                        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let url = navigationAction.request.url?.absoluteString
        if(url != nil && !url!.starts(with:"about:blank") && url! != "https://servedbyadbutler.com/" && url! != "http://servedbyadbutler.com/"){
//            if (url!.range(of:"vast://") != nil){
//                if(url!.range(of:"vastresponse?xml=") != nil){
//                    let range = url!.range(of:"vast://vastresponse?xml=")
//                    let from = range?.upperBound
//                    let to = url!.endIndex
//                    let xml = String(url![from!..<to])
//                    PWVASTParser(self).parseXML(xml.decodeUrl()!)
//                }else{
//                    let range = url!.range(of:"vast://")
//                    let from = range?.upperBound
//                    let to = url!.endIndex
//                    let event = String(url![from!..<to])
//                    handleEvent(event)
//                }
//            }
        }
        decisionHandler(.allow)
        return
    }
    
    public func setVastXML(_ body:String){
        let range = body.range(of:"vast://vastresponse?xml=")
        let from = range?.upperBound
        let to = body.endIndex
        let xml = String(body[from!..<to])
        ABVASTParser(self).parseXML(xml.decodeUrl()!)
    }
    
    func handleEvent(_ event:String){
        switch(event){
        case "mute":
            self.vastDelegate!.onMute()
        case "unmute":
            self.vastDelegate!.onUnmute()
        case "pause":
            self.vastDelegate!.onPause()
        case "resume":
            self.vastDelegate!.onResume()
            
        case "rewind":
            self.vastDelegate!.onRewind()
        case "skip":
            self.vastDelegate!.onSkip()
            if(endCardCompanion != nil){
                videoPlayer?.endCardCompanion = endCardCompanion
                videoPlayer?.displayEndCard()
            }else{
                videoPlayer?.close()
                videoPlayer = nil
            }
        case "playerExpand":
            self.vastDelegate!.onPlayerExpand()
            
        case "playerCollapse":
            self.vastDelegate!.onPlayerCollapse()
            
        case "notUsed":
            self.vastDelegate!.onNotUsed()
            
        case "loaded":
            self.vastDelegate!.onLoaded()
            
        case "start":
            self.vastDelegate!.onStart()
            
        case "firstQuartile":
            self.vastDelegate!.onFirstQuartile()
            
        case "midpoint":
            self.vastDelegate!.onMidpoint()
            
        case "thirdQuartile":
            self.vastDelegate!.onThirdQuartile()
            
        case "complete":
            self.vastDelegate!.onComplete()
            if(endCardCompanion != nil){
                videoPlayer?.endCardCompanion = endCardCompanion
                videoPlayer?.displayEndCard()
            }else{
                videoPlayer?.close()
                videoPlayer = nil
            }
        case "closeLinear":
            self.vastDelegate!.onCloseLinear()
        case "onBrowserClosing":
            self.vastDelegate!.onBrowserClosing()
        case "onBrowserOpening":
            self.vastDelegate!.onBrowserOpening()
        case "ready":
            self.ready = true
            self.vastDelegate!.onReady()
        default:
            break
        }
    }
}
