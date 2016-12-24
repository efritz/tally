//
//  ViewController.swift
//  Tally
//
//  Created by Eric Fritz on 12/19/16.
//  Copyright © 2016 Eric Fritz. All rights reserved.
//

import UIKit

let SpinTicks = 4
let Epsilon: CGFloat = 0.00001

class TimedTask {
    var name: String
    var durations: [Duration]

    init(name: String) {
        self.name = name
        self.durations = []
    }

    func start() {
        self.durations.last?.stop()
        self.durations.append(Duration())
    }

    func stop() {
        self.durations.last?.stop()
    }

    func active() -> Bool {
        if let last = self.durations.last {
            return last.active()
        }

        return false
    }

    func elapsed() -> Int {
        return self.durations.map({ $0.elapsed() }).reduce(0, +)
    }

    func currentElapsed() -> Int {
        if self.active(), let d = self.durations.last {
            return d.elapsed()
        }

        return 0
    }
}

class Duration {
    var first: Date
    var final: Date?

    init() {
        self.first = Date()
    }

    func stop() {
        if self.final == nil {
            self.final = Date()
        }
    }

    func active() -> Bool {
        return self.final == nil
    }

    func elapsed() -> Int {
        return Int((self.final ?? Date()).timeIntervalSince(self.first))
    }
}

protocol NewTaskDelegate {
    func makeNewTask()
}

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
            delegate.makeNewTask()
        }
    }
}

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

        self.update()
        self.updateName()
    }
    
    func update() {
        if let task = self.task {
            elapsed.text = formatElapsed(task.elapsed())

            if task.active() {
                self.currentElapsed.text = formatElapsed(task.currentElapsed())
            }
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
        
        // Stop any current animations
        self.outline.layer.removeAllAnimations()
        self.currentElapsed.layer.removeAllAnimations()
        
        // Start update
        task.start()
        self.startSpin()
        
        // Shrink outline
        self.outline.isHidden = false
        self.outline.transform = CGAffineTransform(scaleX: 0, y: 0)
        
        // Shrink elapsed
        self.currentElapsed.isHidden = false
        self.currentElapsed.transform = CGAffineTransform(translationX: self.outline.center.x - self.currentElapsed.center.x, y: 0).scaledBy(x: Epsilon, y: 1)
        
        UIView.animate(withDuration: 0.5, animations: {
            // Grow outline
            self.outline.transform = CGAffineTransform(scaleX: 1, y: 1)
        }, completion: { finished in
            if !finished {
                return
            }
            
            UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseInOut, animations: {
                // Grow elapsed
                self.currentElapsed.transform = CGAffineTransform(scaleX: 1, y: 1)
            }, completion: nil)
        })
    }
    
    func stop() {
        guard let task = self.task else {
            return
        }
        
        // Stop any current animations
        self.outline.layer.removeAllAnimations()
        self.currentElapsed.layer.removeAllAnimations()
        
        // Stop update
        task.stop()
        self.stopSpin()
        
        // Show elapsed
        self.currentElapsed.isHidden = false
        self.currentElapsed.transform = CGAffineTransform(scaleX: 1, y: 1)
        
        // Show outline
        self.outline.isHidden = false
        self.outline.transform = CGAffineTransform(scaleX: 1, y: 1)
        
        UIView.animate(withDuration: 0.5, animations: {
            // Shrink elapsed
            self.currentElapsed.transform = CGAffineTransform(translationX: self.outline.center.x - self.currentElapsed.center.x, y: 0).scaledBy(x: Epsilon, y: 1)
        }, completion: { finished in
            if !finished {
                return
            }
            
            // Hide shrunken view
            self.currentElapsed.isHidden = true
            
            UIView.animate(withDuration: 0.5, animations: {
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
}

protocol TimerStateChangedDelegate {
    func started(index: Int)
    func stopped(index: Int)
}

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, TimerStateChangedDelegate, NewTaskDelegate {
    private var tasks = [TimedTask]()
    private var activeIndex: Int?
    private var expandedIndex: Int?
    private var timer: Timer?

    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Remove separators betewen empty cells
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)

        // TODO - this is test stuff
        tasks.append(TimedTask(name: "t1"))
        tasks.append(TimedTask(name: "t2"))
        tasks.append(TimedTask(name: "t3"))
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // Mark: - Task Creation

    func makeNewTask() {
        let controller = UIAlertController(title: "New Task", message: "What do you want to call it?", preferredStyle: .alert)
        
        controller.addTextField(configurationHandler: nil)
        
        controller.addAction(UIAlertAction(title: "Create", style: .default, handler: { _ in
            if let field = controller.textFields?.first, let name = field.text {
                if name == "" {
                    return
                }
                
                let index = self.tasks.count
                self.tasks.append(TimedTask(name: name))
                
                self.tableView.insertRows(at: [IndexPath(row: self.realIndex(index: index), section: 0)], with: .right)
            }
        }))
        
        controller.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(controller, animated: true, completion: nil)
    }

    // Mark: - Task Editing
    
    func edit(recognizer: UILongPressGestureRecognizer) {
        if recognizer.state != .began {
            return
        }
        
        guard let indexPath = self.tableView.indexPathForRow(at: recognizer.location(in: self.tableView)) else {
            return
        }
        
        if indexPath.section != 0 {
            return
        }
        
        let index = self.taskIndex(index: indexPath.row)
        let task = self.tasks[index]
        let cell = cellAt(index: index)
        
        let controller = UIAlertController(title: "Edit Task", message: "Edit Task '\(task.name)'", preferredStyle: .actionSheet)
        
        controller.addAction(UIAlertAction(title: "Rename", style: .default, handler: { _ in
            self.renameTask(task: task, cell: cell)
        }))
        
        controller.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
            self.deleteTask (task: task, cell: cell)
        }))
        
        controller.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(controller, animated: true, completion: nil)
    }
    
    func expand(recognizer: UIPanGestureRecognizer) {
        guard let indexPath = self.tableView.indexPathForRow(at: recognizer.location(in: self.tableView)) else {
            return
        }
        
        if indexPath.section != 0 {
            return
        }
        
        let taskIndex = self.taskIndex(index: indexPath.row)
        
        if let expandedIndex = self.closeDetail() {
            if expandedIndex == taskIndex {
                return
            }
        }
        
        self.showDetail(index: taskIndex)
    }
    
    private func renameTask(task: TimedTask, cell: TaskCell) {
        let controller = UIAlertController(title: "Rename Task", message: "What do you want to call it?", preferredStyle: .alert)
        
        controller.addTextField(configurationHandler: { field in
            field.text = task.name
        })
        
        controller.addAction(UIAlertAction(title: "Rename", style: .default, handler: { _ in
            if let field = controller.textFields?.first, let name = field.text {
                if name == "" {
                    return
                }
                
                task.name = name
                cell.updateName()
            }
        }))
        
        controller.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(controller, animated: true, completion: nil)
    }
    
    private func deleteTask(task: TimedTask, cell: TaskCell) {
        if let indexPath = self.tableView.indexPath(for: cell) {
            let index = self.taskIndex(index: indexPath.row)
            
            for i in index..<self.tasks.count {
                cellAt(index: i).moveDown()
            }
            
            if let activeIndex = self.activeIndex {
                if activeIndex > index {
                    self.activeIndex = activeIndex - 1
                }
            }
        
            let _ = self.closeDetail()
            self.tasks.remove(at: index)
            self.tableView.deleteRows(at: [indexPath], with: .fade)
        }
        
        if task.active() {
            self.activeIndex = nil
            cell.stop()
        }
    }
    
    // Mark: - Timer State Change

    func started(index: Int) {
        if let index = self.activeIndex {
            cellAt(index: index).stop()
        } else {
            self.timer = Timer.scheduledTimer(withTimeInterval: 0.33, repeats: true) { _ in
                self.update()
            }
        }
        
        self.activeIndex = index
        
        if let expandedIndex = self.expandedIndex {
            if expandedIndex == index {
                if self.tasks[index].durations.count == 1 {
                    self.tableView.reloadRows(at: [IndexPath(row: index + 1, section: 0)], with: .fade)
                } else {
                    self.tableView.insertRows(at: [IndexPath(row: index + 1, section: 0)], with: .fade)
                }
            }
        }
    }

    func stopped(index: Int) {
        self.update()
        
        if let timer = self.timer {
            timer.invalidate()
        }

        self.timer = nil
        self.activeIndex = nil
    }

    func update() {
        guard let index = self.activeIndex else {
            return
        }
        
        cellAt(index: index).update()
        
        if let expandedIndex = self.expandedIndex {
            if expandedIndex == index {
                if let cell = self.tableView.cellForRow(at: IndexPath(row: index + 1, section: 0)) as? TaskDetailCell {
                    cell.update()
                }
            }
        }

        var newIndex = index
        while newIndex > 0 {
            let a = self.tasks[index].elapsed()
            let b = self.tasks[newIndex - 1].elapsed()
            
            if !compareElapsed(a, b) {
                break
            }
            
            newIndex = newIndex - 1
        }
        
        if index == newIndex {
            return
        }
        
        var shouldExpand: Int? = nil
        if let expandedIndex = self.expandedIndex {
            if newIndex <= expandedIndex && expandedIndex <= index {
                let _ = self.closeDetail()
                
                if expandedIndex == index {
                    shouldExpand = newIndex
                } else {
                    shouldExpand = expandedIndex + 1
                }
            }
        }
        
        for i in (newIndex..<index).reversed() {
            cellAt(index: i).moveUp()
            cellAt(index: index).moveDown()
            
            let j = i + 1
            let temp = self.tasks[j]
            self.tasks[j] = self.tasks[i]
            self.tasks[i] = temp
        }
        
        self.tableView.moveRow(at: IndexPath(row: self.realIndex(index: index), section: 0), to: IndexPath(row: self.realIndex(index: newIndex), section: 0))
        
        if let shouldExpand = shouldExpand {
            self.showDetail(index: shouldExpand)
        }
        
        self.activeIndex = newIndex
    }
    
    private func showDetail(index: Int) {
        var paths = [IndexPath]()
        for i in 0..<self.numberOfDetailCellsFor(index: index) {
            paths.append(IndexPath(row: index + i + 1, section: 0))
        }
        
        self.expandedIndex = index
        tableView.insertRows(at: paths, with: .fade)
    }
    
    private func closeDetail() -> Int? {
        guard let expandedIndex = self.expandedIndex else {
            return nil
        }
        
        var paths = [IndexPath]()
        for i in 0..<self.numberOfDetailCellsFor(index: expandedIndex) {
            paths.append(IndexPath(row: expandedIndex + i + 1, section: 0))
        }
        
        self.expandedIndex = nil
        self.tableView.deleteRows(at: paths, with: .fade)
        return expandedIndex
    }

    private func cellAt(index: Int) -> TaskCell {
        return self.tableView.cellForRow(at: IndexPath(row: self.realIndex(index: index), section: 0)) as! TaskCell
    }
    
    private func realIndex(index: Int) -> Int {
        if let expandedIndex = self.expandedIndex {
            if index > expandedIndex {
                return index + self.numberOfDetailCellsFor(index: expandedIndex)
            }
        }
        
        return index
    }
    
    private func taskIndex(index: Int) -> Int {
        if let expandedIndex = self.expandedIndex {
            if index > expandedIndex {
                return index - self.numberOfDetailCellsFor(index: expandedIndex)
            }
        }
        
        return index
    }
    
    private func numberOfDetailCellsFor(index: Int) -> Int {
        return max(1, self.tasks[index].durations.count)
    }

    // MARK: - Table View Data Source

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            if let expandedIndex = self.expandedIndex {
                return self.tasks.count + self.numberOfDetailCellsFor(index: expandedIndex)
            }
            
            return self.tasks.count
        } else {
            return 1
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            if let expandedIndex = self.expandedIndex {
                if indexPath.row > expandedIndex && indexPath.row <= expandedIndex + self.numberOfDetailCellsFor(index: expandedIndex) {
                    return self.makeTaskDetailCell(tableView: tableView, indexPath: indexPath)
                }
            }
            
            return self.makeTaskCell(tableView: tableView, indexPath: indexPath)
        } else {
            return self.makeNewTaskCell(tableView: tableView, indexPath: indexPath)
        }
    }
    
    private func makeTaskCell(tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "task", for: indexPath)
        
        if let cell = cell as? TaskCell {
            let index = self.taskIndex(index: indexPath.row)
            
            cell.setup(task: self.tasks[index], index: index, delegate: self)
            
            // TODO - move to delegate
            cell.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(expand(recognizer:))))
            cell.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(edit(recognizer:))))
        }
        
        return cell
    }
    
    private func makeTaskDetailCell(tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        let expandedIndex = self.expandedIndex!
        let task = self.tasks[expandedIndex]
        
        if task.durations.isEmpty {
            return tableView.dequeueReusableCell(withIdentifier: "emptyHistory", for: indexPath)
        }
    
        let cell = tableView.dequeueReusableCell(withIdentifier: "taskDetail", for: indexPath)
        
        if let cell = cell as? TaskDetailCell {
            let index = indexPath.row - expandedIndex - 1
            let revIndex = self.numberOfDetailCellsFor(index: expandedIndex) - index - 1
            
            cell.setup(task: self.tasks[expandedIndex], index: revIndex)
        }
        
        return cell
    }
    
    private func makeNewTaskCell(tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "newTask", for: indexPath)
        
        if let cell = cell as? NewTaskCell {
            cell.setup(delegate: self)
        }
        
        return cell
    }
}

let MINUTE = 60
let HOUR = 60 * 60
let DAY = 60 * 60 * 24

func minutes(_ seconds: Int) -> Int {
    return seconds / MINUTE
}

func hours(_ seconds: Int) -> Int {
    return seconds / HOUR
}

func days(_ seconds: Int) -> Int {
    return seconds / DAY
}

func compareElapsed(_ a: Int, _ b: Int) -> Bool {
    for threshold in [MINUTE, HOUR, DAY] {
        if b < threshold && a >= threshold {
            return true
        }
    }

    if a < MINUTE {
        return a > b
    }

    if a < HOUR {
        let x = minutes(a) * MINUTE + a - minutes(a) * MINUTE
        let y = minutes(b) * MINUTE + b - minutes(b) * MINUTE

        return x > y
    }

    if a < DAY {
        let x = hours(a) * HOUR + minutes(a - hours(a) * HOUR)
        let y = hours(b) * HOUR + minutes(b - hours(b) * HOUR)

        return x > y
    }

    let x = days(a) * DAY + hours(a - days(a) * DAY)
    let y = days(b) * DAY + hours(b - days(b) * DAY)

    return x > y
}

func formatElapsed(_ seconds: Int) -> String {
    if seconds < MINUTE {
        return "\(seconds)s"
    }

    if seconds < HOUR {
        return "\(minutes(seconds))m\(seconds - minutes(seconds) * MINUTE)s"
    }

    if seconds < DAY {
        return "\(hours(seconds))h\(minutes(seconds - hours(seconds) * HOUR))m"
    }

    return "\(days(seconds))d\(hours(seconds - days(seconds) * DAY))h"
}

func formatTime(_ date: Date?) -> String {
    if let date = date {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yy hh:mm:ssa"
        
        return formatter.string(from: date)
    }
    
    return "-"
}

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
