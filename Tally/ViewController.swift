//
//  ViewController.swift
//  Tally
//
//  Created by Eric Fritz on 12/19/16.
//  Copyright © 2016 Eric Fritz. All rights reserved.
//

import UIKit

protocol NewTaskDelegate {
    func makeNewTask()
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
        
        if let tasks = Database.instance.allTasks() {
            for task in tasks {
                self.tasks.append(task)
            }
        } else {
            // TODO - better recovery
            print("Could not retrieve tasks.")
        }
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
                
                if let task = Database.instance.createTask(name: name) {
                    self.tasks.append(task)
                    self.tableView.insertRows(at: [IndexPath(row: self.realIndex(index: self.tasks.count - 1), section: 0)], with: .right)
                } else {
                    // TODO - better recovery
                    print("Could not create task.")
                }
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
        
        let point = recognizer.location(in: self.tableView)
        
        guard let indexPath = self.tableView.indexPathForRow(at: point) else {
            return
        }
        
        if indexPath.section != 0 {
            return
        }
        
        let index = self.taskIndex(index: indexPath.row)
        let task = self.tasks[index]
        let cell = self.cellAt(index: index)
        
        let controller = UIAlertController(title: "Edit Task", message: "Edit Task '\(task.name)'", preferredStyle: .actionSheet)
        
        controller.addAction(UIAlertAction(title: "Rename", style: .default, handler: { _ in
            self.renameTask(task: task, cell: cell)
        }))
        
        controller.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
            self.deleteTask(task: task, cell: cell)
        }))
        
        controller.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(controller, animated: true, completion: nil)
    }
    
    func editDetail(recognizer: UILongPressGestureRecognizer) {
        if recognizer.state != .began {
            return
        }
        
        let point = recognizer.location(in: self.tableView)
        
        guard let expandedIndex = self.expandedIndex, let indexPath = self.tableView.indexPathForRow(at: point) else {
            return
        }
        
        if indexPath.section != 0 {
            return
        }
        
        let task = self.tasks[expandedIndex]
        let index = indexPath.row - expandedIndex - 1
        let revIndex = self.tasks[expandedIndex].durations.count - index - 1
        let cell = self.detailCellAt(index: revIndex)
        
        let controller = UIAlertController(title: "Edit Detail", message: "Edit Detail for '\(task.name)'", preferredStyle: .actionSheet)
        
        if !task.durations[revIndex].active() {
            controller.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
                self.deleteDuration(duration: task.durations[index], cell: cell, index: revIndex)
            }))
        }
        
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
                
                if !Database.instance.update(task: task, name: name) {
                    // TODO - better recovery
                    print("Could not update task name.")
                }
            }
        }))
        
        controller.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(controller, animated: true, completion: nil)
    }
    
    private func deleteTask(task: TimedTask, cell: TaskCell) {
        if let indexPath = self.tableView.indexPath(for: cell) {
            let index = self.taskIndex(index: indexPath.row)
            
            for i in index..<self.tasks.count {
                self.cellAt(index: i).moveDown()
            }
            
            if let activeIndex = self.activeIndex {
                if activeIndex > index {
                    self.activeIndex = activeIndex - 1
                }
            }
            
            if !Database.instance.delete(task: task) {
                // TODO - better recovery
                print("Could not delete task.")
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
    
    private func deleteDuration(duration: Duration, cell: TaskDetailCell, index: Int) {
        guard let expandedIndex = self.expandedIndex, let indexPath = self.tableView.indexPath(for: cell) else {
            return
        }
        
        for i in index..<duration.task.durations.count {
            self.detailCellAt(index: i).moveDown()
        }
        
        if !Database.instance.delete(duration: duration) {
            // TODO - better recovery
            print("Could not delete duration.")
        }
        
        duration.task.durations.remove(at: index)
        self.tableView.deleteRows(at: [indexPath], with: .fade)
        self.cellAt(index: expandedIndex).update()
    }
    
    // Mark: - Timer State Change

    func started(index: Int) {
        if let index = self.activeIndex {
            self.cellAt(index: index).stop()
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
            self.cellAt(index: i).moveUp()
            self.cellAt(index: index).moveDown()
            
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
    
    private func detailCellAt(index: Int) -> TaskDetailCell {
        let expandedIndex = self.expandedIndex!
        let task = self.tasks[expandedIndex]
        
        return self.tableView.cellForRow(at: IndexPath(row: expandedIndex + task.durations.count - index, section: 0)) as! TaskDetailCell
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
            
            // TDOO - move to delegate
            cell.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(editDetail(recognizer:))))
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
