//
//  ViewController.swift
//  SDKTester
//
//  Created by Will Prevett on 2019-06-05.
//  Copyright © 2019 Will Prevett. All rights reserved.
//

import UIKit
import AdButler

class ViewController: UIViewController , UITextFieldDelegate, ABInterstitialDelegate, ABVASTDelegate, UIPickerViewDelegate, UIPickerViewDataSource {

    @IBOutlet weak var btnGetBanner: UIButton!
    @IBOutlet weak var btnGetInterstitial: UIButton!
    @IBOutlet weak var btnGetVASTVideo: UIButton!
    
    @IBOutlet weak var txtAccountID: UITextField!
    @IBOutlet weak var txtZoneID: UITextField!
    @IBOutlet weak var txtPublisherID: UITextField!
    
    @IBOutlet weak var txtLog: UITextView!
    
    @IBOutlet weak var btnTopLeft: UIButton!
    @IBOutlet weak var btnTopCenter: UIButton!
    @IBOutlet weak var btnTopRight: UIButton!
    @IBOutlet weak var btnCenterLeft: UIButton!
    @IBOutlet weak var btnCenter: UIButton!
    @IBOutlet weak var btnCenterRight: UIButton!
    @IBOutlet weak var btnBottomCenter: UIButton!
    @IBOutlet weak var btnBottomLeft: UIButton!
    @IBOutlet weak var btnBottomRight: UIButton!
    
    @IBOutlet weak var btnDisplayInterstitial: UIButton!
    @IBOutlet weak var btnDismiss: UIButton!
    
    @IBOutlet weak var viewOrientation: UIView!
    
    @IBOutlet weak var pickerOrientation: UIPickerView!
    
    @IBOutlet weak var bannerContainer: UIView!
    
    @IBOutlet weak var lblPicker: UIButton!
    let pickerData:[String] = ["none", "portrait", "landscape"]
    
    var accountID:Int!
    var zoneID:Int!
    var publisherID:Int!
    
    var selectedPosition:UIButton? = nil
    let selectedColor = UIColor.init(rgb:0x007AFF)
    let unselectedColor = UIColor.init(rgb:0xEFEFEF)
    
    var interstitialReady:Bool = false
    var sdk:SDKConsumer! = nil
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sdk = SDKConsumer(parentViewController:self)
        let log:(String)->Void={ str in
            self.log(str)
        }
        sdk.setLoggingFunction(log)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        sdk.banner?.destroy()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        AdButler.initialize(mainView: self.view)
        txtAccountID.delegate = self
        txtZoneID.delegate = self
        txtPublisherID.delegate = self
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action:#selector(self.closeTextBoxes(_:))))
        sdk.setInterstitialDelegate(self)
        sdk.setVASTDelegate(self)
        pickerOrientation.delegate = self
        pickerOrientation.dataSource = self
        pickerOrientation.isHidden = true
        lblPicker.isUserInteractionEnabled = true
        
    }

    @IBAction func pickerTouchDown(_ sender: Any) {
        lblPicker.isHidden = true
        pickerOrientation.isHidden = false
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool{
        textField.resignFirstResponder()
        return true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Number of columns of data
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    // Capture the picker view selection
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        // This method is triggered whenever the user makes a change to the picker selection.
        // The parameter named row and component represents what was selected.
        lblPicker.setTitle(pickerData[row], for:UIControl.State.normal)
        lblPicker.isHidden = false
        pickerOrientation.isHidden = true
    }
    
    // The number of rows of data
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData.count
    }
    
    // The data to return fopr the row and component (column) that's being passed in
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerData[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        var label = UILabel()
        if let v = view {
            label = v as! UILabel
        }
        label.font = UIFont (name: "Helvetica Neue", size: 10)
        label.text =  pickerData[row]
        label.textAlignment = .left
        return label
    }
    
    @IBAction func onPositionClicked(_ sender: UIButton) {
        selectPosition(sender)
    }
    
    func selectPosition(_ btn:UIButton){
        if(btn == selectedPosition){
            selectedPosition?.backgroundColor = unselectedColor
            selectedPosition = nil
        }else{
            selectedPosition?.backgroundColor = unselectedColor
            btn.backgroundColor = selectedColor
            selectedPosition = btn
        }
    }
    
    @objc func closeTextBoxes(_ sender:Any){
        if(txtAccountID.isFirstResponder){
            txtAccountID.resignFirstResponder()
        }
        if(txtZoneID.isFirstResponder){
            txtZoneID.resignFirstResponder()
        }
        if(txtPublisherID.isFirstResponder){
            txtPublisherID.resignFirstResponder()
        }
    }
    
    func setInterstitialReady(_ ready:Bool){
        interstitialReady = ready
        btnDisplayInterstitial.isHidden = !ready
    }
    
    @IBAction func onGetBannerClick(_ sender: Any) {
        if(!validateInputs(includePublisher:false)){
            return
        }
        let pos:String? = getPositionString()
        sdk.setPosition(pos)
        if(pos != nil){
            sdk.getBanner(accountID:self.accountID, zoneID:self.zoneID)
        }else{
            sdk.getBanner(accountID:self.accountID, zoneID:self.zoneID, container:bannerContainer)
        }
        btnDismiss.isHidden = false
    }
    
    @IBAction func onGetInterstitialClick(_ sender: Any) {
        if(!validateInputs(includePublisher:false)){
            return
        }
        setInterstitialReady(false)
        sdk.getInterstitial(accountID:self.accountID, zoneID:self.zoneID)
    }
    
    @IBAction func onGetVASTVideoClick(_ sender: Any) {
        log("Retrieving VAST Video - will autoplay when ready...")
        if(!validateInputs(includePublisher:true)){
            return
        }
        var orientationMask:UIInterfaceOrientationMask? = nil
        if(lblPicker.currentTitle! == "portrait") {orientationMask = [ .portrait ]}
        if(lblPicker.currentTitle! == "landscape") {orientationMask = [ .landscapeLeft ]}
        
        sdk.getVASTVideo(accountID: self.accountID, zoneID: self.zoneID, publisherID: self.publisherID, orientationMask:orientationMask)
    }
    
    @IBAction func onDisplayInterstitialClick(_ sender: Any) {
        setInterstitialReady(false)
        sdk.displayInterstitial()
    }
    @IBAction func onDismissClick(_ sender: Any) {
        sdk.banner?.destroy()
        btnDismiss.isHidden = true
    }
    
    func validateInputs(includePublisher:Bool) -> Bool{
        let accountText = txtAccountID.text
        if(accountText == nil || accountText!.isEmpty){
            log("Invalid account ID")
            return false
        }else{
            let accountID = Int(accountText!) ?? 0
            if(accountID == 0){
                log("Invalid account ID")
                return false
            }else{
                self.accountID = accountID
            }
        }
        
        let zoneText = txtZoneID.text
        if(zoneText == nil || zoneText!.isEmpty){
            log("Invalid zone ID")
            return false
        }else{
            let zoneID = Int(zoneText!) ?? 0
            if(zoneID == 0){
                log("Invalid zone ID")
                return false
            }else{
                self.zoneID = zoneID
            }
        }
        
        if(includePublisher){
            let publisherText = txtPublisherID.text
            if(publisherText == nil || publisherText!.isEmpty){
                log("Invalid publisher ID")
                return false
            }else{
                let publisherID = Int(publisherText!) ?? 0
                if(publisherID == 0){
                    log("Invalid publisher ID")
                    return false
                }else{
                    self.publisherID = publisherID
                }
            }
        }
        
        return true
    }
    
    func getPositionString() -> String? {
        switch(selectedPosition){
        case btnTopLeft:
            return Positions.TOP_LEFT
        case btnTopCenter:
            return Positions.TOP_CENTER
        case btnTopRight:
            return Positions.TOP_RIGHT
        case btnCenterLeft:
            return Positions.CENTER_LEFT
        case btnCenter:
            return Positions.CENTER
        case btnCenterRight:
            return Positions.CENTER_RIGHT
        case btnBottomLeft:
            return Positions.BOTTOM_LEFT
        case btnBottomCenter:
            return Positions.BOTTOM_CENTER
        case btnBottomRight:
            return Positions.BOTTOM_RIGHT
        default:
            return nil
        }
    }
    
    
    // DELEGATE FUNCTIONS
    func log(_ str:String){
        txtLog.text = ("> " + str + "\n" + txtLog.text).trunc(length:32767) // int16.max
        NSLog(str) // also log to xcode
    }
    
    func interstitialReady(_ interstitial: ABInterstitial) {
        log("Interstitial :: ready")
        setInterstitialReady(true)
    }
    
    func interstitialFailedToLoad(_ interstitial: ABInterstitial) {
        log("Interstitial :: failed")
    }
    
    func interstitialClosed(_ interstitial: ABInterstitial) {
        log("Interstitial :: close")
    }
    
    func interstitialStartLoad(_ interstitial: ABInterstitial) {
        log("Interstitial :: start load")
    }
    
    func onMute() {
        log("VAST :: mute")
    }
    
    func onUnmute() {
        log("VAST :: unmute")
    }
    
    func onPause() {
        log("VAST :: pause")
    }
    
    func onResume() {
        log("VAST :: resume")
    }
    
    func onRewind() {
        log("VAST :: rewind")
    }
    
    func onSkip() {
        log("VAST :: skip")
    }
    
    func onPlayerExpand() {
        log("VAST :: playerExpand")
    }
    
    func onPlayerCollapse() {
        log("VAST :: playerCollapse")
    }
    
    func onNotUsed() {
        log("VAST :: notUsed")
    }
    
    func onLoaded() {
        log("VAST :: loaded")
    }
    
    func onStart() {
        log("VAST :: start")
    }
    
    func onFirstQuartile() {
        log("VAST :: firstQuartile")
    }
    
    func onMidpoint() {
        log("VAST :: midpoint")
    }
    
    func onThirdQuartile() {
        log("VAST :: thirdQuartile")
    }
    
    func onComplete() {
        log("VAST :: complete")
    }
    
    func onCloseLinear() {
        log("VAST :: closeLinear")
    }
    
    func onBrowserOpening(){
        log("VAST :: onBrowserOpening")
    }
    
    func onBrowserClosing(){
        log("VAST :: onBrowserClosing")
    }
    
    func onReady(){
        log("VAST :: onReady")
        log("Autoplaying VAST")
        self.sdk.displayVASTVideo()
    }
    
    func onError(){
        log("VAST :: onError")
    }
}



