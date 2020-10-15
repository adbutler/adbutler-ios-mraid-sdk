//
//  FrequencyCappingManager.swift
//  AdButler
//
//  Created by Will Prevett on 2020-10-13.
//  Copyright © 2020 Will Prevett. All rights reserved.
//

import Foundation

public class FrequencyCappingManager: NSObject {
    private let freqCapFileName: String = "ab_freq_cap.txt"
    private var data: [FrequencyCappingData]
    
    public override init() {
        self.data = []
        super.init()
        readFile()
    }
    
    public func getData() -> [FrequencyCappingData] {
        return self.data;
    }
    
    public func parseResponseData(_ p:Placement){
        if(p.placementId == nil || p.views == nil || p.start == nil || p.expiry == nil){
            return;
        }else{
            updateData(placementId: p.placementId!, views: p.views!, start: p.start!, expiry: p.expiry!)
        }
    }
    
    public func updateData(placementId:String, views:String, start:String, expiry:String){
        var found:Bool = false
        for item in self.data {
            if(item.placement_id == placementId){
                found = true
                item.views = views
                item.start = start
                item.expiry = expiry
                writeFile()
                break
            }
        }
        if(!found){
            let datum = FrequencyCappingData(placementId: placementId, views: views, start: start, expiry: expiry)
            self.data.append(datum)
            writeFile()
        }
    }
    
    private func readFile(){
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = dir.appendingPathComponent(self.freqCapFileName)
            do {
                let content = try String(contentsOf: fileURL, encoding: .utf8)
                let lines = content.split { $0.isNewline }
                let timestamp = Int64(NSDate().timeIntervalSince1970)
                for line in lines {
                    let s = line.split(separator: ",")
                    let expiry = String(s[3])
                    let expiryInt = Int64(expiry)
                    if(expiryInt != nil && expiryInt! >= timestamp){
                        self.data.append(FrequencyCappingData(placementId: String(s[0]), views: String(s[1]), start: String(s[2]), expiry: String(s[3])))
                    }
                }
            }
            catch {
                // File doesn't exist... that's fine.
            }
        }
    }
    
    private func writeFile(){
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = dir.appendingPathComponent(self.freqCapFileName)
            var content = "";
            for item in self.data {
                content.append("\(item.placement_id),\(item.views),\(item.start),\(item.expiry)\n")
            }
            do {
                try content.write(to: fileURL, atomically: false, encoding: .utf8)
            }
            catch {
                // error writing file
                print("AdButler :: Error writing to frequency capping file.")
            }
        }
    }
}
