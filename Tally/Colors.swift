//
//  Colors.swift
//  Tally
//
//  Created by Eric Fritz on 12/23/16.
//  Copyright © 2016 Eric Fritz. All rights reserved.
//

import UIKit

let mix = UIColor.white

func makeRandomColor(mix: UIColor) -> UIColor {
    let r = CGFloat(arc4random_uniform(255)) / 255
    let g = CGFloat(arc4random_uniform(255)) / 255
    let b = CGFloat(arc4random_uniform(255)) / 255
    
    let mr = CIColor(color: mix).red
    let mg = CIColor(color: mix).green
    let mb = CIColor(color: mix).blue
    
    return UIColor(ciColor: CIColor(
        red: (r + mr) / 2,
        green: (g + mg) / 2,
        blue: (b + mb) / 2
    ))
}

