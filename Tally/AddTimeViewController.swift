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

class AddTimeViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    @IBOutlet weak var navItem: UINavigationItem!
    @IBOutlet weak var durationPicker: UIPickerView!
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
        
        // Don't allow future time
        datePicker.maximumDate = Date()
        
        // Set default duration (1 hours, 0 min)
        durationPicker.selectRow(1, inComponent: 0, animated: false)
        durationPicker.selectRow(0, inComponent: 1, animated: false)
    }
    
    // Mark: - Dismissing
    
    @IBAction func onCancel(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onSave(_ sender: UIBarButtonItem) {
        guard let task = self.task else {
            return
        }
        
        let duration = self.durationPicker.selectedRow(inComponent: 0) * 3600 + self.durationPicker.selectedRow(inComponent: 1) * 60
        
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
    
    // Mark: - Duration Picker
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 2
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if component == 0 {
            return 24
        }
        
        return 60
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return  component == 0 ? "hours" : "min"
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let label = UILabel()
        label.text = "\(row)"
        return label
    }
}
