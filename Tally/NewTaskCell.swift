//
//  NewTaskCell.swift
//  Tally
//
//  Created by Eric Fritz on 12/23/16.
//  Copyright © 2016 Eric Fritz. All rights reserved.
//

import UIKit

class NewTaskCell: UITableViewCell {
    private var delegate: NewTaskDelegate?
    
    @IBOutlet weak var outline: UIView!
    
    func setup(delegate: NewTaskDelegate) {
        self.delegate = delegate
        
        self.outline.layer.cornerRadius = self.outline.layer.bounds.width / 2
        self.outline.clipsToBounds = true
    }
    
    @IBAction func create(_ sender: UIButton) {
        UIView.animate(withDuration: 0.15, delay: 0, options: .curveEaseIn, animations: {
            sender.transform = CGAffineTransform(scaleX: 1.75, y: 1.75).rotated(by: CGFloat(Float.pi))
            self.outline.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
        }, completion: { _ in
            UIView.animate(withDuration: 0.15, delay: 0, options: .curveEaseOut, animations: {
                sender.transform = CGAffineTransform(scaleX: 1, y: 1)
                self.outline.transform = CGAffineTransform(scaleX: 1, y: 1)
            }, completion: nil)
        })
        
        if let delegate = self.delegate {
            delegate.shouldMakeNewTask()
        }
    }
}
