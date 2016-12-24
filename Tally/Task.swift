//
//  Task.swift
//  Tally
//
//  Created by Eric Fritz on 12/23/16.
//  Copyright © 2016 Eric Fritz. All rights reserved.
//

import UIKit

class Duration {
    var first: Date
    var final: Date?
    
    init() {
        self.first = Date()
    }
    
    func stop() {
        if self.final == nil {
            self.final = Date()
        }
    }
    
    func active() -> Bool {
        return self.final == nil
    }
    
    func elapsed() -> Int {
        return Int((self.final ?? Date()).timeIntervalSince(self.first))
    }
}

class TimedTask {
    var name: String
    var durations: [Duration]
    
    init(name: String) {
        self.name = name
        self.durations = []
    }
    
    func start() {
        self.durations.last?.stop()
        self.durations.append(Duration())
    }
    
    func stop() {
        self.durations.last?.stop()
    }
    
    func active() -> Bool {
        if let last = self.durations.last {
            return last.active()
        }
        
        return false
    }
    
    func elapsed() -> Int {
        return self.durations.map({ $0.elapsed() }).reduce(0, +)
    }
    
    func currentElapsed() -> Int {
        if self.active(), let d = self.durations.last {
            return d.elapsed()
        }
        
        return 0
    }
}
