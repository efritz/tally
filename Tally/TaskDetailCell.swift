//
//  TaskDetailCell.swift
//  Tally
//
//  Created by Eric Fritz on 12/23/16.
//  Copyright © 2016 Eric Fritz. All rights reserved.
//

import UIKit

class TaskDetailCell: UITableViewCell {
    @IBOutlet weak var first: UILabel!
    @IBOutlet weak var final: UILabel!
    @IBOutlet weak var elapsed: UILabel!
    @IBOutlet weak var note: UILabel!
    
    private var task: TimedTask?
    private var index: Int?
    
    func setup(task: TimedTask, index: Int) {
        self.task = task
        self.index = index
        
        // Set colors (UILabel background not animateable)
        self.elapsed.backgroundColor = UIColor.clear
        self.elapsed.layer.backgroundColor = task.color.cgColor
        
        // Set content immediately
        self.update()
    }
    
    func update() {
        guard let task = self.task, let index = self.index else {
            return
        }
        
        self.first.text = "at " + formatTime(task.durations[index].first)
        self.elapsed.text = formatElapsed(task.durations[index].elapsed())
        self.note.text = task.durations[index].note ?? ""
    }
    
    func moveUp() {
        if let index = self.index {
            self.index = index + 1
        }
    }
    
    func moveDown() {
        if let index = self.index {
            self.index = index - 1
        }
    }
}
