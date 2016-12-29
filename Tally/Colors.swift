//
//  Colors.swift
//  Tally
//
//  Created by Eric Fritz on 12/23/16.
//  Copyright © 2016 Eric Fritz. All rights reserved.
//

import UIKit

extension UIColor {
    var coreImageColor: CIColor {
        return CIColor(color: self)
    }
    
    var components: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        let color = coreImageColor
        return (color.red, color.green, color.blue, color.alpha)
    }
}

func makeRandomColor(mix: UIColor) -> UIColor {
    let r = Float(arc4random_uniform(255)) / 255
    let g = Float(arc4random_uniform(255)) / 255
    let b = Float(arc4random_uniform(255)) / 255
    
    return mixColors(UIColor(colorLiteralRed: r, green: g, blue: b, alpha: 1), UIColor.white)
}

func mixColors(_ a: UIColor, _ b: UIColor) -> UIColor {
    let (r1, g1, b1, a1) = a.components
    let (r2, g2, b2, a2) = b.components
    
    return UIColor(colorLiteralRed: Float(r1 + r2) / 2,
                   green: Float(g1 + g2) / 2,
                   blue: Float(b1 + b2) / 2,
                   alpha: Float(a1 + a2) / 2)
}
