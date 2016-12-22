//
//  ViewController.swift
//  Tally
//
//  Created by Eric Fritz on 12/19/16.
//  Copyright © 2016 Eric Fritz. All rights reserved.
//

import UIKit

let SpinTicks = 4
let Epsilon: CGFloat = 0.001

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
            sender.transform = CGAffineTransform(scaleX: 1.75, y: 1.75)
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
    private lazy var elapsedTarget: CGFloat = { [unowned self] in
        return self.currentElapsed.center.x
    }()

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

        self.currentElapsed.isHidden = true
        self.currentElapsed.layer.cornerRadius = 5
        self.currentElapsed.clipsToBounds = true

        self.outline.isHidden = true
        self.outline.layer.cornerRadius = self.outline.layer.bounds.width / 2
        self.outline.clipsToBounds = true

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
        
        task.start()
        self.startSpin()
        
        // Ensure value is calculated
        let target = self.elapsedTarget
        
        // Stop any current animations
        self.outline.layer.removeAllAnimations()
        self.currentElapsed.layer.removeAllAnimations()
        
        // Ensure state at end of animation
        self.currentElapsed.center.x = self.outline.center.x
        self.currentElapsed.transform = CGAffineTransform(scaleX: Epsilon, y: 1)
        self.outline.isHidden = true
        self.currentElapsed.isHidden = true
        
        self.outline.isHidden = false
        self.outline.transform = CGAffineTransform(scaleX: 0, y: 0)

        UIView.animate(withDuration: 0.5, animations: {
            self.outline.transform = CGAffineTransform(scaleX: 1, y: 1)
        }, completion: { finished in
            if !finished {
                return
            }
            
            self.currentElapsed.isHidden = false
            self.currentElapsed.center.x = self.outline.center.x
            self.currentElapsed.transform = CGAffineTransform(scaleX: 0, y: 1)

            UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseInOut, animations: {
                self.currentElapsed.center.x = target
                self.currentElapsed.transform = CGAffineTransform(scaleX: 1, y: 1)
            }, completion: nil)
        })
    }
    
    func stop() {
        guard let task = self.task else {
            return
        }
        
        task.stop()
        self.stopSpin()

        // Stop any current animations
        self.outline.layer.removeAllAnimations()
        self.currentElapsed.layer.removeAllAnimations()
        
        // Ensure state at end of animation
        self.currentElapsed.isHidden = false
        self.outline.transform = CGAffineTransform(scaleX: 1, y: 1)
        self.currentElapsed.center.x = self.elapsedTarget
        self.currentElapsed.transform = CGAffineTransform(scaleX: 1, y: 1)
        
        UIView.animate(withDuration: 0.5, animations: {
            self.currentElapsed.center.x = self.outline.center.x
            self.currentElapsed.transform = CGAffineTransform(scaleX: Epsilon, y: 1)
        }, completion: { finished in
            if !finished {
                return
            }
            
            self.currentElapsed.isHidden = true

            UIView.animate(withDuration: 0.5, animations: {
                self.outline.transform = CGAffineTransform(scaleX: Epsilon, y: Epsilon)
            }, completion: { finished in
                if !finished {
                    return
                }
                
                self.outline.isHidden = true
                self.currentElapsed.isHidden = true
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

protocol TimerStateChangedDelegate {
    func started(index: Int)
    func stopped(index: Int)
}

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, TimerStateChangedDelegate, NewTaskDelegate {
    private var tasks = [TimedTask]()
    private var activeIndex: Int?
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
                
                self.tasks.append(TimedTask(name: name))
                self.tableView.insertRows(at: [IndexPath(row: self.tasks.count - 1, section: 0)], with: .right)
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
        
        guard let index = self.tableView.indexPathForRow(at: recognizer.location(in: self.tableView)) else {
            return
        }
        
        let task = self.tasks[index.row]
        let cell = cellAt(index: index.row)
        
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
        if task.active() {
            self.activeIndex = nil
            cell.stop()
        }
        
        if let index = self.tableView.indexPath(for: cell)?.row {
            for i in index..<self.tasks.count {
                cellAt(index: i).moveDown()
            }
            
            if let activeIndex = self.activeIndex {
                if activeIndex > index {
                    self.activeIndex = activeIndex - 1
                }
            }
        
            self.tasks.remove(at: index)
            self.tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .fade)
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

        self.update()
        self.activeIndex = index
    }

    func stopped(index: Int) {
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

        var newIndex = index

        while newIndex > 0 {
            let a = self.tasks[newIndex].elapsed()
            let b = self.tasks[newIndex - 1].elapsed()

            if !compareElapsed(a, b) {
                break
            }

            cellAt(index: index).moveDown()
            cellAt(index: newIndex - 1).moveUp()

            let temp = self.tasks[newIndex]
            self.tasks[newIndex] = self.tasks[newIndex - 1]
            self.tasks[newIndex - 1] = temp

            newIndex = newIndex - 1
        }

        if newIndex != index {
            self.tableView.moveRow(at: IndexPath(row: index, section: 0), to: IndexPath(row: newIndex, section: 0))
        }

        self.activeIndex = newIndex
    }

    private func cellAt(index: Int) -> TaskCell {
        return self.tableView.cellForRow(at: IndexPath(row: index, section: 0)) as! TaskCell
    }

    // MARK: - Table View

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return tasks.count
        } else {
            return 1
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "task", for: indexPath)

            if let cell = cell as? TaskCell {
                cell.setup(task: self.tasks[indexPath.row], index: indexPath.row, delegate: self)
                // TODO - move to delegate
                cell.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(edit(recognizer:))))
            }

            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "newTask", for: indexPath)
            
            if let cell = cell as? NewTaskCell {
                cell.setup(delegate: self)
            }
            
            return cell
        }
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
