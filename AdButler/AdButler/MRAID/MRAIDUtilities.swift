//
//  MRAIDUtilities.swift
//  AdButler
//

//  Copyright © 2018 AdButler, Inc. All rights reserved.
//

import Foundation
import SystemConfiguration
import EventKit
import WebKit

public class MRAIDUtilities {
    
    internal static func validateHTML(_ htmlBody:inout String){
        replaceMRAIDScript(htmlBody: &htmlBody)
        verifyHtmlStructure(htmlBody: &htmlBody)
    }
    
    private static func replaceMRAIDScript(htmlBody:inout String){
        let pattern = "<script\\s+[^>]*\\bsrc\\s*=\\s*\\\\?([\\\\\"\\\\'])mraid\\.js\\\\?\\1[^>]*>[^<]*<\\/script>\\n*"
        let regex = try! NSRegularExpression(pattern: pattern, options: NSRegularExpression.Options.caseInsensitive)
        let range = NSMakeRange(0, htmlBody.count)
        let injectString = "<script src=\"" + MRAIDJSLocation + "?v=" + String(NSDate().timeIntervalSince1970 * 1000) + "\"></script>"
        htmlBody = regex.stringByReplacingMatches(in: htmlBody, options: [], range: range, withTemplate:injectString)
    }
    
    private static func verifyHtmlStructure(htmlBody:inout String){
        // Check for body
        let body = htmlBody.range(of:"<body")
        if(body == nil){
            htmlBody = "<body style=\"margin:0\">\n" + htmlBody + "</body>"
        }
        
        // Check for header
        let head = htmlBody.range(of:"<head")
        let metaString = "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0, minimum-scale=1.0, maximum-scale=1.0, user-scalable=no\" />"
        if(head == nil){
            htmlBody = "<head>\n" + metaString + "\n</head>\n" + htmlBody
        }else {
            // header exists, now make sure we have viewport meta tag
            let metaPattern = "<meta[^>*]name\\s*=\\s*\\\\?['\"]viewport\\\\?['\"][^>]*>"
            let regex = try! NSRegularExpression(pattern:metaPattern, options: NSRegularExpression.Options.caseInsensitive)
            let range = NSMakeRange(0, htmlBody.count)
            if(regex.matches(in: htmlBody, range: range).count == 0){
                let headPattern = "<head[^>]*>"
                let headRegex = try! NSRegularExpression(pattern:headPattern, options: NSRegularExpression.Options.caseInsensitive)
                let matches = headRegex.matches(in:htmlBody, range:range)
                if(matches.count > 0){
                    // this is ridiculous but there doesn't seem to be any working splice functionality, and I wasted enough time looking for some
                    let left = String(htmlBody.prefix(upTo: htmlBody.index(htmlBody.startIndex, offsetBy: matches[0].range.upperBound)))
                    let right = String(htmlBody.suffix(from: htmlBody.index(htmlBody.startIndex, offsetBy: matches[0].range.upperBound)))
                    htmlBody = left + "\n" + metaString + right
                }
            }
        }
        
        // Check for html
        let html = htmlBody.range(of:"<html")
        if(html == nil){
            htmlBody = "<html>\n" + htmlBody + "\n</html>"
        }
    }
    
    internal static func checkForLazyLoadedMRAID(_ webView:WKWebView){
        let js = "document.documentElement.outerHTML"
        webView.evaluateJavaScript(js, completionHandler: { (val:Any?, error:Error?) in
            let body = val.debugDescription
            let pattern = "<script\\s+[^>]*\\bsrc\\s*=\\s*\\\\?([\\\\\"\\\\'])mraid\\.js\\\\?\\1[^>]*>[^<]*<\\/script>\\n*"
            let regex = try! NSRegularExpression(pattern: pattern, options: NSRegularExpression.Options.caseInsensitive)
            let range = NSMakeRange(0, body.count)
            let matches = regex.numberOfMatches(in:body, options:[], range:range)
            if(matches > 0){
                let js = """
                    var scr = document.createElement("script");
                    scr.setAttribute('src', '\(MRAIDJSLocation + "?v=" + String(NSDate().timeIntervalSince1970 * 1000))');
                    scr.setAttribute('type', 'text/javascript');
                    head.appendChild(scr);
                """
                webView.evaluateJavaScript(js, completionHandler: { (val:Any?, error:Error?) in
                    let js = "document.documentElement.outerHTML"
                    webView.evaluateJavaScript(js, completionHandler: nil)
                })
            }
        })
    }
    
    internal static func parseDate(_ str:String) -> Date? {
        let iso = ISO8601DateFormatter()
        let isoDate = iso.date(from:str)
        if(isoDate != nil){
            return isoDate!
        }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier:"en_US_POSIX")
        let formats = [
            "yyyy-MM-dd'T'HH:mmZZZZZ" ,
            "yyyy-MM-dd'T'HH:mm:ssZZZZZ" ,
            "yyyy-MM-dd" ,
            "yyyy-MM-dd'T'HHZZZZZ"
            ]
        for format in formats {
            formatter.dateFormat = format
            let date = formatter.date(from:str)
            if(date != nil){
                return date!;
            }
        }
        return nil
    }
    
    internal static func addCalendarItem(mraidEvent:MRAIDCalendarEvent) -> Bool {
        let eventStore = EKEventStore()
        let event:EKEvent = EKEvent(eventStore: eventStore)
        
        event.title = mraidEvent.description
        event.location = mraidEvent.location
        
        guard let startDate:Date = parseDate(mraidEvent.start) else {
            //throw(MRAIDError.invalidStartDate)
            return false
        }
        event.startDate = startDate
        guard let endDate = (mraidEvent.end != nil ? parseDate(mraidEvent.end!) : startDate) else {
            //throw(MRAIDError.invalidEndDate)
            return false
        }
        event.endDate = endDate
        
        let expiry = (mraidEvent.recurrence?.expires != nil ? parseDate(mraidEvent.recurrence!.expires!) : nil)
        event.calendar = eventStore.defaultCalendarForNewEvents
        
        // recurrence
        var recurrence = mraidEvent.recurrence
        if(recurrence != nil){
            if(recurrence!.frequency != nil){
                var frequency:EKRecurrenceFrequency? = nil
                switch(recurrence!.frequency){
                    case "weekly":
                        frequency = EKRecurrenceFrequency.weekly
                    case "daily":
                        frequency = EKRecurrenceFrequency.daily
                    case "monthly":
                        frequency = EKRecurrenceFrequency.monthly
                    case "yearly":
                        frequency = EKRecurrenceFrequency.yearly
                    default:
                        break
                }
                var daysInWeek:[EKRecurrenceDayOfWeek]? = nil
                if(frequency != nil){
                    if(recurrence?.daysInWeek != nil){
                        daysInWeek = []
                        for num in recurrence!.daysInWeek!{
                            if(num > 0 && num < 8){
                                daysInWeek!.append(EKRecurrenceDayOfWeek(EKWeekday(rawValue:num)!))
                            }
                        }
                    }
                    let validateDays = {(_ arr:[Int]?, max:Int) -> [Int]? in
                        if(arr != nil){
                            var newArr:[Int] = []
                            for num in arr!{
                                if(num > 0 && num <= max){
                                    newArr.append(num)
                                }
                            }
                            return newArr
                        }
                        return arr
                    }
                    recurrence!.daysInMonth = validateDays(recurrence!.daysInMonth, 31)
                    recurrence!.monthsInYear = validateDays(recurrence!.monthsInYear, 12)
                    recurrence!.weeksInYear = validateDays(recurrence!.weeksInYear, 52)
                    recurrence!.daysInYear = validateDays(recurrence!.daysInYear, 365)
                
                    let frequencyRule = EKRecurrenceRule(recurrenceWith: frequency!,
                                                     interval: 1,
                                                     daysOfTheWeek: daysInWeek,
                                                     daysOfTheMonth: recurrence!.daysInMonth as [NSNumber]?,
                                                     monthsOfTheYear: recurrence!.monthsInYear as [NSNumber]?,
                                                     weeksOfTheYear: recurrence!.weeksInYear as [NSNumber]?,
                                                     daysOfTheYear: recurrence!.daysInYear as [NSNumber]?,
                                                     setPositions: nil,
                                                     end: expiry != nil ? EKRecurrenceEnd(end: expiry!) : nil)
                    event.addRecurrenceRule(frequencyRule)
                }
            }
        }
        
        // save Event
        do{
            try eventStore.save(event, span:.thisEvent)
        }catch{
            // Failed to save event.  Elevate the error
            //throw MRAIDError.invalidCalendarEvent
            return false
        }
        
        // reminder
        if(mraidEvent.reminder != nil){
            let status = EKEventStore.authorizationStatus(for: EKEntityType.reminder)
            if(status == .authorized){
                saveCalendarReminder(mraidEvent:mraidEvent, eventStore:eventStore, event:event)
            } else{
                let bundleDict = Bundle.main.infoDictionary
                if(bundleDict?["NSRemindersUsageDescription"] != nil){
                    EKEventStore().requestAccess(to: EKEntityType.reminder, completion: {
                        (accessGranted: Bool, error: Error?) in
                            if accessGranted == true {
                                saveCalendarReminder(mraidEvent:mraidEvent, eventStore:eventStore, event:event)
                            }
                        }
                    )
                }
            }
        }
        return true
    }
    
    private static func saveCalendarReminder(mraidEvent:MRAIDCalendarEvent, eventStore:EKEventStore, event:EKEvent) {
        let reminder = EKReminder(eventStore:eventStore)
        reminder.calendar = eventStore.defaultCalendarForNewReminders()
        
        let reminderDate = parseDate(mraidEvent.reminder!)
        let reminderMS = Int(mraidEvent.reminder!)
        
        let startComponents = Calendar.current.dateComponents(in: event.timeZone ?? TimeZone.current, from: event.startDate)
        var dueDateComponents:DateComponents? = nil
        if(reminderDate != nil){
            // set as date
            dueDateComponents = Calendar.current.dateComponents(in: event.timeZone ?? TimeZone.current, from: reminderDate!)
        }else if(reminderMS != nil){
            // set as milliseconds from event
            let relativeDate = event.startDate.addingTimeInterval(TimeInterval(reminderMS! / 1000)) // time interval is seconds, mraid passes milliseconds
            dueDateComponents = Calendar.current.dateComponents(in: event.timeZone ?? TimeZone.current, from: relativeDate)
        }
        reminder.startDateComponents = startComponents
        reminder.dueDateComponents = dueDateComponents
        
        // copy the main event's recurrence rules
        if(event.recurrenceRules != nil){
            for rule in event.recurrenceRules!{
                reminder.addRecurrenceRule(EKRecurrenceRule(
                    recurrenceWith: rule.frequency,
                    interval: rule.interval,
                    daysOfTheWeek: rule.daysOfTheWeek,
                    daysOfTheMonth: rule.daysOfTheMonth,
                    monthsOfTheYear: rule.monthsOfTheYear,
                    weeksOfTheYear: rule.weeksOfTheYear,
                    daysOfTheYear: rule.daysOfTheYear,
                    setPositions: rule.setPositions,
                    end: rule.recurrenceEnd)
                )
            }
        }
        
        reminder.title = event.title
        if(dueDateComponents?.date != nil){
            reminder.addAlarm(EKAlarm(absoluteDate: dueDateComponents!.date!))
        }
        
        do{
            try eventStore.save(reminder, commit: true)
        }catch{
            // Failed to save reminder.  Elevate the error
            print(error.localizedDescription)
        }
    }
    
    internal static func deserialize<T: Codable>(_ args:String) throws -> T? {
        do{
            let argsStr = args.decodeUrl()
            let obj = try JSONDecoder().decode(T.self, from:argsStr!.data(using: .utf8)!)
            return obj
        }catch {
            //TODO error deserializing
            print("Error deserializing")
        }
        return nil
    }
    
    internal static func getExpandedUrlContent(_ url:String, completion:@escaping (_ url:String) -> Void) {
        guard let url = URL(string: url.decodeUrl()!) else {
            print("Error: cannot create URL")
            return
        }
        let urlRequest = URLRequest(url: url)
        
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        
        // make the request
        let task = session.dataTask(with: urlRequest) {
            (data, response, error) in
            // check for any errors
            guard error == nil else {
                NSLog(error!.localizedDescription)
                return
            }
            // make sure we got data
            guard let responseData = data else {
                NSLog("Error: did not receive data")
                return
            }
            guard var resStr = String(data: responseData, encoding: .utf8) else {
                NSLog("Response data not convertable to string .utf8")
                return
            }
            
            MRAIDUtilities.validateHTML(&resStr)
            completion(resStr)
        }
        task.resume()
    }
    
    internal static func setRootController(_ controller:UIViewController){
        UIApplication.shared.delegate?.window??.addSubview(controller.view)
        UIApplication.shared.delegate?.window??.rootViewController = controller
    }
}

