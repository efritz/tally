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
    
    private var task: TimedTask?
    private var index: Int?
    
    func setup(task: TimedTask, index: Int) {
        self.task = task
        self.index = index
        
        self.update()
    }
    
    func update() {
        guard let task = self.task, let index = self.index else {
            return
        }
        
        self.first.text = formatTime(task.durations[index].first)
        self.final.text = formatTime(task.durations[index].final)
        
        self.elapsed.text = formatElapsed(task.durations[index].elapsed())
    }
    
    func moveDown() {
        if let index = self.index {
            self.index = index - 1
        }
    }
}
