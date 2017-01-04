//
//  SummaryView.swift
//  Tally
//
//  Created by Eric Fritz on 1/2/17.
//  Copyright © 2017 Eric Fritz. All rights reserved.
//

import UIKit

class SummaryView: UIView {
    var durations: [Duration]?
    
    private var i = 0
    override func draw(_ rect: CGRect) {
        guard let durations = self.durations?.sorted(by: { $0.first < $1.first }).map({ d in (d.task.color, Double(d.elapsed())) }) else {
            return
        }
        
        var first = 0.0
        let total = durations.map({ $0.1 }).reduce(0, +)
        
        for (color, elapsed) in durations {
            let a = first
            let b = first + elapsed
            first = b
            
            self.drawDuration(a: a / total, b: b / total, color: color)
        }
    }
    
    private func drawDuration(a: Double, b: Double, color: UIColor) {
        let w = Double(self.bounds.width)
        let h = Double(self.bounds.height)
        let r = CGRect(x: a * w, y: 0, width: b * w, height: h)
        
        if let context = UIGraphicsGetCurrentContext() {
            context.setFillColor(color.cgColor)
            context.setStrokeColor(color.cgColor)
            context.fill(r)
            context.stroke(r)
        }
    }
}
