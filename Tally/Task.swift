//
//  Task.swift
//  Tally
//
//  Created by Eric Fritz on 12/23/16.
//  Copyright © 2016 Eric Fritz. All rights reserved.
//

import UIKit

class TimedTask {
    let id: Int64
    var name: String
    var durations: [Duration]
    var color: UIColor
    
    init(id: Int64, name: String, durations: [Duration] = [], color: UIColor = UIColor.white) {
        self.id = id
        self.name = name
        self.durations = durations
        self.color = color
    }
    
    func start() {
        self.stop()
        
        if let duration = Database.instance.createDuration(for: self) {
            self.durations.append(duration)
        } else {
            // better recovery
            print("Could not create duration.")
        }
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
