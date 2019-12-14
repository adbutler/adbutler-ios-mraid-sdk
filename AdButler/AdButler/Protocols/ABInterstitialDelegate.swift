//
//  ABInterstitialDelegate.swift
//  AdButler
//
//  Created by Will Prevett on 2018-06-05.
//  Copyright © 2018 AdButler. All rights reserved.
//
public protocol ABInterstitialDelegate {
    // called when the interstitial content is finished loading
    func interstitialReady(_ interstitial:ABInterstitial)
    
    // called when an error occurs loading the interstitial content
    func interstitialFailedToLoad(_ interstitial:ABInterstitial)
    
    // called when the interstitial has close, and disposed of it's views
    func interstitialClosed(_ interstitial:ABInterstitial)
    
    // called when the HTML request starts to load
    func interstitialStartLoad(_ interstitial:ABInterstitial)
}
