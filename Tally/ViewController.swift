//
//  ViewController.swift
//  Tally
//
//  Created by Eric Fritz on 12/19/16.
//  Copyright © 2016 Eric Fritz. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDataSource, TaskCollectionDelegate, TimerStateChangedDelegate, NewTaskDelegate, TimeAddedDelegate, NoteAddedDelegate {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var navItem: UINavigationItem!
    @IBOutlet weak var summaryView: SummaryView!
    
    private var taskCollection = TaskCollection.load()
    
    private var segueTask: TimedTask?
    private var segueDurationIndex: Int?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Remove separators betewen empty cells
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        
        self.taskCollection.delegate = self
        self.updateGlobal()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //
    // Mark: - ???
    
    private func updateGlobal() {
        self.navItem.title = "All Tasks - \(formatElapsed(self.taskCollection.elapsed()))"
        
        self.summaryView.durations = self.taskCollection.durations()
        self.summaryView.setNeedsDisplay()
    }
    
    private func renameTask(task: TimedTask) {
        let controller = UIAlertController(title: "Rename Task \(task.name)", message: "What would you rather call it?", preferredStyle: .alert)
        
        controller.addTextField(configurationHandler: { field in
            field.text = task.name
        })
        
        controller.addAction(UIAlertAction(title: "Ok", style: .default, handler: { _ in
            if let field = controller.textFields?.first, let name = field.text {
                if name == "" {
                    return
                }
                
                guard let index = self.taskCollection.index(of: task) else {
                    return
                }
                
                if !Database.instance.update(task: task, name: name) {
                    // better recovery
                    print("Could not update task name.")
                }
                
                task.name = name
                self.cellAt(index: self.taskCollection.taskIndex(tableIndex: index))?.updateName()
            }
        }))
        
        controller.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(controller, animated: true, completion: nil)
    }
    
    private func deleteDuration(duration: Duration, index: Int) {
        guard let (taskIndex, task) = self.taskCollection.expanded() else {
            return
        }
        
        // TODO - move most of this logic into task collection
        
        if !Database.instance.delete(duration: duration) {
            print("Could not delete duration.")
            return
        }
        
        for i in index..<task.durations.count {
            self.detailCellAt(index: taskIndex + task.durations.count - i)?.moveDown()
        }
        
        let indexPath = IndexPath(row: taskIndex + task.durations.count - index, section: 0)
        
        task.durations.remove(at: index)
        
        if task.durations.count == 0 {
            self.tableView.reloadRows(at: [indexPath], with: .fade)
        } else {
            self.tableView.deleteRows(at: [indexPath], with: .fade)
        }
        
        guard let index = self.taskCollection.index(of: task) else {
            return
        }
        
        self.updateGlobal()
        self.taskCollection.reorder(index: index)
        self.cellAt(index: self.taskCollection.taskIndex(tableIndex: taskIndex))?.update()
    }

    //
    // Mark: - Data Delegates
    
    func stopTask(index: Int) {
        self.cellAt(index: self.taskCollection.taskIndex(tableIndex: index))?.stop()
    }
    
    func updateTask(index: Int) {
        self.updateGlobal()
        self.cellAt(index: index)?.update()
    }
    
    func updateDetail(index: Int) {
        self.detailCellAt(index: index)?.update()
    }
    
    func moveTaskCell(from: Int, to: Int) {
        if from < to {
            for i in (from+1)...to {
                self.cellAt(index: i)?.moveDown()
                self.cellAt(index: from)?.moveUp()
            }
        } else {
            for i in to..<from {
                self.cellAt(index: i)?.moveUp()
                self.cellAt(index: from)?.moveDown()
            }
        }
        
        self.tableView.moveRow(at: IndexPath(row: from, section: 0), to: IndexPath(row: to, section: 0))
    }
    
    func addTaskCell(index: Int) {
        self.tableView.insertRows(at: [IndexPath(row: index, section: 0)], with: .fade)
    }
    
    func removeTaskCell(index: Int) {
        for i in index..<self.tableView.numberOfRows(inSection: 0) {
            self.cellAt(index: i)?.moveDown()
        }
        
        self.tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .fade)
        self.updateGlobal()
    }
    
    func addDetailCells(indices: [Int]) {
        self.tableView.insertRows(at: indices.map({ IndexPath(row: $0, section: 0) }), with: .fade)
    }
    
    func removeDetailCells(indices: [Int]) {
        self.tableView.deleteRows(at: indices.map({ IndexPath(row: $0, section: 0) }), with: .fade)
    }
    
    //
    // Mark: - Cell Delegates
    
    // TODO - instead, just make the task collection the delegate

    func started(index: Int) {
        self.taskCollection.start(index: index)
    }
    
    func stopped(index: Int) {
        self.taskCollection.stop()
    }
    
    //
    // Mark: - Controller Delegates
    
    func makeNewTask() {
        let controller = UIAlertController(title: "Create Task", message: "What would you like to call it?", preferredStyle: .alert)
        
        controller.addTextField(configurationHandler: nil)
        
        controller.addAction(UIAlertAction(title: "Create", style: .default, handler: { _ in
            if let field = controller.textFields?.first, let name = field.text {
                if name == "" {
                    return
                }
                
                self.taskCollection.createTask(named: name)
            }
        }))
        
        controller.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(controller, animated: true, completion: nil)
    }
    
    func addTime(first: Date, final: Date) {
        guard let task = self.segueTask else {
            return
        }
        
        guard let duration = Database.instance.createDuration(for: task, first: first, final: final) else {
            // better recovery
            print("Could not create task detail.")
            return
        }
        
        //
        // TODO - move some of this logic into task view as well
        //
        
        var i = 0
        while i < task.durations.count && first >= task.durations[i].first {
            i = i + 1
        }
        
        // Insert sorted
        task.durations.insert(duration, at: i)
        
        guard let index = self.taskCollection.index(of: task) else {
            return
        }
        
        // Update elapsed count
        self.cellAt(index: self.taskCollection.taskIndex(tableIndex: index))?.update()
        
        // If expanded, insert new row
        if let (expandedIndex, task) = self.taskCollection.expanded() {
            if expandedIndex == index {
                let indexPath = IndexPath(row: index + task.durations.count - i, section: 0)
                
                if task.durations.count == 1 {
                    self.tableView.reloadRows(at: [indexPath], with: .fade)
                } else {
                    self.tableView.insertRows(at: [indexPath], with: .fade)
                    
                    i = i + 1
                    while i < task.durations.count {
                        self.detailCellAt(index: expandedIndex + i)?.moveUp()
                        i = i + 1
                    }
                }
            }
        }
        
        self.updateGlobal()
        self.taskCollection.reorder(index: index)
    }
    
    func editNote(note: String) {
        guard let task = self.segueTask, let index = self.segueDurationIndex, let taskIndex = self.taskCollection.index(of: task) else {
            return
        }
        
        let duration = task.durations[index]
        
        if !Database.instance.update(duration: duration, withNote: note == "" ? nil : note) {
            // better recovery
            print("Could not update task detail note.")
            return
        }

        self.detailCellAt(index: self.taskCollection.taskIndex(tableIndex: taskIndex) + task.durations.count - index)?.update()
    }
    
    //
    // Mark: - Gesture Recognizers in Cells
        
    func expand(recognizer: UITapGestureRecognizer) {
        guard let indexPath = self.tableView.indexPathForRow(at: recognizer.location(in: self.tableView)) else {
            return
        }
        
        if indexPath.section != 0 {
            return
        }
        
        self.taskCollection.toggleExpansion(index: self.taskCollection.taskIndex(tableIndex: indexPath.row))
    }
    
    func edit(recognizer: UILongPressGestureRecognizer) {
        if recognizer.state != .began {
            return
        }
        
        let point = recognizer.location(in: self.tableView)
        
        guard let indexPath = self.tableView.indexPathForRow(at: point) else {
            return
        }
        
        let task = self.taskCollection.task(at: self.taskCollection.taskIndex(tableIndex: indexPath.row))
        
        let controller = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        controller.addAction(UIAlertAction(title: "Rename Task", style: .default, handler: { _ in
            self.renameTask(task: task)
        }))
        
        controller.addAction(UIAlertAction(title: "Add Time", style: .default, handler: { _ in
            self.segueTask = task
            self.performSegue(withIdentifier: "addTime", sender: nil)
        }))
        
        controller.addAction(UIAlertAction(title: "Delete Task", style: .default, handler: { _ in
            self.taskCollection.delete(task: task)
        }))
        
        controller.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(controller, animated: true, completion: nil)
    }
    
    func editDetail(recognizer: UILongPressGestureRecognizer) {
        if recognizer.state != .began {
            return
        }
        
        let point = recognizer.location(in: self.tableView)
        
        guard let indexPath = self.tableView.indexPathForRow(at: point) else {
            return
        }
        
        guard let (index, task) = self.taskCollection.expanded() else {
            return
        }
        
        let revIndex = index + task.durations.count - indexPath.row
        let duration = task.durations[revIndex]
        
        let controller = UIAlertController(title: nil, message: duration.active() ? "Note: An active task detail cannot be deleted." : nil, preferredStyle: .actionSheet)
        
        controller.addAction(UIAlertAction(title: duration.note == nil ? "Add note" : "Update note", style: .default, handler: { _ in
            self.segueTask = task
            self.segueDurationIndex = revIndex
            self.performSegue(withIdentifier: "addNote", sender: nil)
        }))
        
        if !duration.active() {
            controller.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
                self.deleteDuration(duration: duration, index: revIndex)
            }))
        }
        
        controller.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(controller, animated: true, completion: nil)
    }
    
    //
    // Mark: - Segues
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let controller = (segue.destination as? UINavigationController)?.topViewController else {
            return
        }
        
        if segue.identifier == "addTime" {
            guard let controller = controller as? AddTimeViewController else {
                return
            }
            
            if let task = self.segueTask {
                controller.task = task
                controller.durations = self.taskCollection.durations()
                controller.delegate = self
            }
        }
        
        if segue.identifier == "addNote" {
            guard let controller = controller as? AddNoteViewController else {
                return
            }
            
            if let task = self.segueTask, let index = self.segueDurationIndex {
                controller.duration = task.durations[index]
                controller.delegate = self
            }
        }
    }
    
    //
    // MARK: - Table View Data Source

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section != 0 {
            return 1
        }
        
        return self.taskCollection.numberOfCells()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section != 0 {
            return self.makeNewTaskCell(tableView: tableView, indexPath: indexPath)
        }
        
        if self.taskCollection.detailIndices().contains(indexPath.row) {
            return self.makeTaskDetailCell(tableView: tableView, indexPath: indexPath)
        }
        
        return self.makeTaskCell(tableView: tableView, indexPath: indexPath)
    }
    
    private func makeTaskCell(tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "task", for: indexPath)
        
        if let cell = cell as? TaskCell {
            let index = self.taskCollection.taskIndex(tableIndex: indexPath.row)
            
            cell.setup(task: self.taskCollection.task(at: index), index: index, delegate: self)
            cell.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(expand(recognizer:))))
            cell.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(edit(recognizer:))))
        }
        
        return cell
    }
    
    private func makeTaskDetailCell(tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        let (taskIndex, task) = self.taskCollection.expanded()!
        
        if task.durations.isEmpty {
            return tableView.dequeueReusableCell(withIdentifier: "emptyHistory", for: indexPath)
        }
    
        let cell = tableView.dequeueReusableCell(withIdentifier: "taskDetail", for: indexPath)
        
        if let cell = cell as? TaskDetailCell {
            let detailIndex = taskIndex + self.taskCollection.numberOfDetailCellsFor(index: taskIndex) - indexPath.row
            
            cell.setup(task: task, index: detailIndex)
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
    
    // Mark: - Cell Accessors
    
    func cellAt(index: Int) -> TaskCell? {
        return self.tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? TaskCell
    }
    
    func detailCellAt(index: Int) -> TaskDetailCell? {
        return self.tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? TaskDetailCell
    }
    
}
