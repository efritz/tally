//
//  Duration.swift
//  Tally
//
//  Created by Eric Fritz on 12/24/16.
//  Copyright © 2016 Eric Fritz. All rights reserved.
//

import UIKit

class Duration {
    let id: Int64
    let task: TimedTask
    var first: Date
    var final: Date?
    var note: String?
    
    init(id: Int64, task: TimedTask, first: Date, final: Date? = nil, note: String? = nil) {
        self.id = id
        self.task = task
        self.first = first
        self.final = final
        self.note = note
    }
    
    func intersects(first: Date, final: Date?) -> Bool {
        let a = self.first <= first ? self.final : final
        let b = self.first <= first ? first : self.first
        
        if let c = a, c <= b {
            return false
        }
        
        return true
    }
    
    func stop() {
        if self.final != nil {
            return
        }
        
        if !Database.instance.update(duration: self) {
            // better recovery
            print("Could not update duration.")
        }
    }
    
    func active() -> Bool {
        return self.final == nil
    }
    
    func elapsed() -> Int {
        return Int((self.final ?? Date()).timeIntervalSince(self.first))
    }
}
