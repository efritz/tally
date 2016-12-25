//
//  Formatting.swift
//  Tally
//
//  Created by Eric Fritz on 12/23/16.
//  Copyright © 2016 Eric Fritz. All rights reserved.
//

import UIKit

let MINUTE = 60
let HOUR = 60 * 60
let DAY = 60 * 60 * 24

func minutes(_ seconds: Int) -> Int {
    return seconds / MINUTE
}

func hours(_ seconds: Int) -> Int {
    return seconds / HOUR
}

func days(_ seconds: Int) -> Int {
    return seconds / DAY
}

func compareElapsed(_ a: Int, _ b: Int) -> Bool {
    for threshold in [MINUTE, HOUR, DAY] {
        if b < threshold && a >= threshold {
            return true
        }
    }
    
    if a < MINUTE {
        return a > b
    }
    
    if a < HOUR {
        let x = minutes(a) * MINUTE + a - minutes(a) * MINUTE
        let y = minutes(b) * MINUTE + b - minutes(b) * MINUTE
        
        return x > y
    }
    
    if a < DAY {
        let x = hours(a) * HOUR + minutes(a - hours(a) * HOUR)
        let y = hours(b) * HOUR + minutes(b - hours(b) * HOUR)
        
        return x > y
    }
    
    let x = days(a) * DAY + hours(a - days(a) * DAY)
    let y = days(b) * DAY + hours(b - days(b) * DAY)
    
    return x > y
}

func formatElapsed(_ seconds: Int) -> String {
    if seconds < MINUTE {
        return "\(seconds)s"
    }
    
    if seconds < HOUR {
        return "\(minutes(seconds))m\(seconds - minutes(seconds) * MINUTE)s"
    }
    
    if seconds < DAY {
        return "\(hours(seconds))h\(minutes(seconds - hours(seconds) * HOUR))m"
    }
    
    return "\(days(seconds))d\(hours(seconds - days(seconds) * DAY))h"
}

func formatTime(_ date: Date?) -> String {
    if let date = date {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd hh:mma"
        
        return formatter.string(from: date)
    }
    
    return "-"
}
