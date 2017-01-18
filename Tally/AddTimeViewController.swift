//
//  AddTimeViewController.swift
//  Tally
//
//  Created by Eric Fritz on 12/27/16.
//  Copyright © 2016 Eric Fritz. All rights reserved.
//

import UIKit

class AddTimeViewController: UITableViewController {
    @IBOutlet weak var navItem: UINavigationItem!
    @IBOutlet weak var durationPicker: UIDatePicker!
    @IBOutlet weak var datePicker: UIDatePicker!
    
    private var showingDatePicker = false
    private var showingDurationPicker = false
    
    var task: TimedTask? {
        didSet {
            self.configureView()
        }
    }
    
    var durations: [Duration]?
    var delegate: TimeAddedDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Remove separators betewen empty cells
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        
        // Try to set initial data
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
        
        // Set default values
        self.durationPicker.countDownDuration = 60
        self.datePicker.setDate(Date(), animated: true)
        
        // Don't allow future start times
        self.datePicker.maximumDate = Date()
        
        // Set initial label values
        self.onStartChanged(self.datePicker)
        self.onDurationChanged(self.durationPicker)
    }
    
    // Mark: - Dismissing
    
    @IBAction func onCancel(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onSave(_ sender: UIBarButtonItem) {
        guard let durations = self.durations else {
            return
        }
        
        let duration = self.durationPicker.countDownDuration
        
        // Calculate date points
        let first = self.datePicker.date
        let final = first.addingTimeInterval(duration)
        
        if final > Date() {
            self.showError(message: "The duration provided ends in the future.")
            return
        }
        
        for duration in durations {
            if duration.intersects(first: first, final: final) {
                self.showIntersectionError(duration: duration)
                return
            }
        }
        
        self.delegate?.shouldAddTime(from: first, to: final)
        self.dismiss(animated: true, completion: nil)
    }
    
    private func showIntersectionError(duration: Duration) {
        if duration.active() {
            self.showError(message: "The duration provided intersects with the active timer.")
            return
        }
        
        let t = formatTime(duration.first)
        let d = formatElapsed(duration.elapsed())
        let p = duration.task.id != self.task?.id ? " in task \(duration.task.name)" : ""
        
        self.showError(message: "The duration provided intersects with the \(d) timer starting at \(t)\(p).")
    }
    
    private func showError(message: String) {
        let controller = UIAlertController(title: "Cannot add time to task", message: message, preferredStyle: .alert)
        
        controller.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        self.present(controller, animated: true, completion: nil)
    }
    
    // Mark: - Picker Observers
    
    @IBAction func onDurationChanged(_ sender: UIDatePicker) {
        if let cell = self.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) {
            cell.detailTextLabel?.text = formatElapsed(Int(sender.countDownDuration))
        }
    }
    
    @IBAction func onStartChanged(_ sender: UIDatePicker) {
        if let cell = self.tableView.cellForRow(at: IndexPath(row: 2, section: 0)) {
            cell.detailTextLabel?.text = formatTime(sender.date)
        }
    }
    
    // Mark: - Show/Hide Pickers
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 1 && !self.showingDurationPicker {
            return 0
        }
        
        if indexPath.row == 3 && !self.showingDatePicker {
            return 0
        }
        
        return super.tableView(self.tableView, heightForRowAt: indexPath)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            self.showingDurationPicker = !self.showingDurationPicker
            
            if self.showingDurationPicker {
                self.showingDatePicker = false
            }
        }
        
        if indexPath.row == 2 {
            self.showingDatePicker = !self.showingDatePicker
            
            if self.showingDatePicker {
                self.showingDurationPicker = false
            }
        }
        
        self.tableView.beginUpdates()
        self.tableView.endUpdates()
        self.tableView.deselectRow(at: indexPath, animated: true)
    }
}
