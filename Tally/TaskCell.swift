//
//  TaskCell.swift
//  Tally
//
//  Created by Eric Fritz on 12/23/16.
//  Copyright © 2016 Eric Fritz. All rights reserved.
//

import UIKit

let SpinTicks = 4
let Epsilon: CGFloat = 0.00001

class TaskCell: UITableViewCell {
    private var task: TimedTask?
    private var index: Int?
    private var delegate: TimerStateChangedDelegate?
    
    private var moving = false
    private var animating = false
    private var animationCount = 0
    
    @IBOutlet weak var elapsed: UILabel!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var currentElapsed: UILabel!
    @IBOutlet weak var toggle: UIButton!
    @IBOutlet weak var outline: UIView!
    
    func setup(task: TimedTask, index: Int, delegate: TimerStateChangedDelegate) {
        self.task = task
        self.index = index
        self.delegate = delegate
        
        // Fix view depths
        self.contentView.sendSubview(toBack: self.currentElapsed)
        self.contentView.sendSubview(toBack: self.name)
        
        // Setup, hide outline
        self.outline.isHidden = true
        self.outline.layer.cornerRadius = self.outline.layer.bounds.width / 2
        self.outline.clipsToBounds = true
        
        // Setup, hide elapsed
        self.currentElapsed.isHidden = true
        self.currentElapsed.layer.cornerRadius = 5
        self.currentElapsed.clipsToBounds = true
        
        // Create colors
        let r = makeRandomColor(mix: UIColor.white)
        self.elapsed.backgroundColor = r
        self.outline.backgroundColor = r
        self.currentElapsed.backgroundColor = r
        
        // See if we were active when app started
        if task.active() {
            self.startAnimation()
            delegate.started(index: index)
        }
        
        self.update()
        self.updateName()
    }
    
    func update() {
        guard let task = self.task else {
            return
        }
        
        elapsed.text = formatElapsed(task.elapsed())
        
        if task.active() {
            self.currentElapsed.text = formatElapsed(task.currentElapsed())
        }
    }
    
    func updateName() {
        if let task = self.task {
            self.name.text = task.name
        }
    }
    
    func moveDown() {
        if let index = self.index {
            self.index = index - 1
        }
    }
    
    func moveUp() {
        if let index = self.index {
            self.index = index + 1
        }
    }
    
    func start() {
        guard let task = self.task else {
            return
        }
        
        task.start()
        self.startAnimation()
    }
    
    func stop() {
        guard let task = self.task else {
            return
        }
        
        // Stop update
        task.stop()
        self.stopAnimation()
    }
    
    private func startAnimation() {
        // Stop any current animations
        self.outline.layer.removeAllAnimations()
        self.currentElapsed.layer.removeAllAnimations()
        
        // Begin spinner
        self.startSpin()
        
        // Shrink outline
        self.outline.isHidden = false
        self.outline.transform = CGAffineTransform(scaleX: 0, y: 0)
        
        // Shrink elapsed
        self.currentElapsed.isHidden = false
        self.currentElapsed.transform = CGAffineTransform(translationX: self.outline.center.x - self.currentElapsed.center.x, y: 0).scaledBy(x: Epsilon, y: 1)
        
        UIView.animate(withDuration: 0.25, animations: {
            // Grow outline
            self.outline.transform = CGAffineTransform(scaleX: 1, y: 1)
        }, completion: { finished in
            if !finished {
                return
            }
            
            UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut, animations: {
                // Grow elapsed
                self.currentElapsed.transform = CGAffineTransform(scaleX: 1, y: 1)
            }, completion: nil)
        })
    }
    
    private func stopAnimation() {
        // Stop any current animations
        self.outline.layer.removeAllAnimations()
        self.currentElapsed.layer.removeAllAnimations()
        
        // Stop spinner
        self.stopSpin()
        
        // Show elapsed
        self.currentElapsed.isHidden = false
        self.currentElapsed.transform = CGAffineTransform(scaleX: 1, y: 1)
        
        // Show outline
        self.outline.isHidden = false
        self.outline.transform = CGAffineTransform(scaleX: 1, y: 1)
        
        UIView.animate(withDuration: 0.25, animations: {
            // Shrink elapsed
            self.currentElapsed.transform = CGAffineTransform(translationX: self.outline.center.x - self.currentElapsed.center.x, y: 0).scaledBy(x: Epsilon, y: 1)
        }, completion: { finished in
            if !finished {
                return
            }
            
            // Hide shrunken view
            self.currentElapsed.isHidden = true
            
            UIView.animate(withDuration: 0.25, animations: {
                // Shrink outline
                self.outline.transform = CGAffineTransform(scaleX: Epsilon, y: Epsilon)
            }, completion: { finished in
                if !finished {
                    return
                }
                
                // Hide shrunken view
                self.outline.isHidden = true
            })
        })
    }
    
    @IBAction func toggled(_ sender: UIButton) {
        guard let task = self.task, let index = self.index, let delegate = self.delegate else {
            return
        }
        
        if !task.active() {
            start()
            delegate.started(index: index)
        } else {
            stop()
            delegate.stopped(index: index)
        }
        
        self.update()
    }
    
    // Mark: - Spin Animation
    
    private func startSpin() {
        if self.animating {
            return
        }
        
        self.animating = true
        
        if !self.moving {
            self.animationCount = 0
            self.spin()
        }
    }
    
    private func stopSpin() {
        self.animating = false
    }
    
    private func spin() {
        self.moving = true
        self.animationCount = (self.animationCount + 1) % SpinTicks
        
        UIView.animate(withDuration: 1 / Double(SpinTicks), delay: 0, options: [.allowUserInteraction, .curveLinear], animations: {
            self.toggle.transform = self.toggle.transform.rotated(by: 2 * CGFloat(Float.pi) / CGFloat(SpinTicks))
        }, completion: { _ in
            if self.animating {
                self.spin()
            } else {
                if self.animationCount != 0 {
                    self.spin()
                } else {
                    self.moving = false
                }
            }
        })
    }
}
