//
//  MRAIDInterstitialDelegate.swift
//  AdButler
//
//  Created by Will Prevett on 2018-08-24.
//  Copyright © 2018 Will Prevett. All rights reserved.
//

public protocol MRAIDInterstitialDelegate {
    // called when the interstitial content is finished loading
    func interstitialReady(_ interstitial:ABMRAIDInterstitial)
    
    // called when an error occurs loading the interstitial content
    func interstitialFailedToLoad(_ interstitial:ABMRAIDInterstitial)
    
    // called when the interstitial has close, and disposed of it's views
    func interstitialClosed(_ interstitial:ABMRAIDInterstitial)
    
    // called when the HTML request starts to load
    func interstitialStartLoad(_ interstitial:ABMRAIDInterstitial)
}
