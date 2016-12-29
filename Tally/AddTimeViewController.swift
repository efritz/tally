//
//  AddTimeViewController.swift
//  Tally
//
//  Created by Eric Fritz on 12/27/16.
//  Copyright © 2016 Eric Fritz. All rights reserved.
//

import UIKit

protocol TimeAddedDelegate {
    func addTime(first: Date, final: Date)
}

class AddTimeViewController: UIViewController {
    @IBOutlet weak var navItem: UINavigationItem!
    @IBOutlet weak var durationPicker: UIDatePicker!
    @IBOutlet weak var datePicker: UIDatePicker!
    
    var task: TimedTask? {
        didSet {
            self.configureView()
        }
    }
    
    var delegate: TimeAddedDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureView()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // Mark: - Layout view
    
    private func configureView() {
        guard let task = self.task, self.datePicker != nil else {
            return
        }
        
        // Set title
        self.navItem.title = "Task \(task.name)"
        
        // Set default duration
        durationPicker.countDownDuration = 3600
        
        // Don't allow future time
        datePicker.maximumDate = Date()
    }
    
    // Mark: - Dismissing
    
    @IBAction func onCancel(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onSave(_ sender: UIBarButtonItem) {
        guard let task = self.task else {
            return
        }
        
        let duration = self.durationPicker.countDownDuration
        
        // Calculate date points
        let first = self.datePicker.date
        let final = first.addingTimeInterval(TimeInterval(duration))
        
        for duration in task.durations {
            if duration.intersects(first: first, final: final) {
                var message: String
                if duration.active() {
                    message = "The duration provided intersects with the active timer started at \(formatTime(duration.first))."
                } else {
                    message = "The duration provided intersects with a \(formatElapsed(duration.elapsed())) timer starting at \(formatTime(duration.first))."
                }
                
                let controller = UIAlertController(title: "Cannot add time to task", message: message, preferredStyle: .alert)
                
                controller.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                self.present(controller, animated: true, completion: nil)
                return
            }
        }
        
        self.delegate?.addTime(first: first, final: final)
        self.dismiss(animated: true, completion: nil)
    }
}
