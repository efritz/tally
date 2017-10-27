//
//  ViewController.swift
//  Tally
//
//  Created by Eric Fritz on 12/19/16.
//  Copyright © 2016 Eric Fritz. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, TaskCollectionDelegate, NewTaskDelegate, TimeAddedDelegate, NoteChangedDelegate {
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
    
    //
    // Mark: - Action Sheet Callbacks
    
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
    
    //
    // Mark: - Data Delegates
    
    func stopTaskCell(at tableIndex: Int) {
        self.cellAt(index: tableIndex)?.stop()
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
    
    func moveDetailCell(index: Int, up: Bool) {
        if let cell = self.detailCellAt(index: index) {
            up ? cell.moveUp() : cell.moveDown()
        }
    }
    
    func insertTaskCell(at tableIndex: Int) {
        self.tableView.insertRows(at: [IndexPath(row: tableIndex, section: 0)], with: .fade)
    }
    
    func deleteTaskCell(at tableIndex: Int) {
        for i in tableIndex..<self.tableView.numberOfRows(inSection: 0) {
            self.cellAt(index: i)?.moveDown()
        }
        
        self.tableView.deleteRows(at: [IndexPath(row: tableIndex, section: 0)], with: .fade)
        self.updateGlobal()
    }
    
    func updateTaskCell(at tableIndex: Int) {
        self.cellAt(index: tableIndex)?.update()
        self.updateGlobal()
    }
    
    func insertDetailCells(at tableIndices: [Int]) {
        self.tableView.insertRows(at: tableIndices.map({ IndexPath(row: $0, section: 0) }), with: .fade)
    }
    
    func deleteDetailCells(at tableIndices: [Int]) {
        self.tableView.deleteRows(at: tableIndices.map({ IndexPath(row: $0, section: 0) }), with: .fade)
    }
    
    func reloadDetailCells(at tableIndices: [Int]) {
        for index in tableIndices {
            self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .fade)
        }
    }
    
    func updateDetailCells(at tableIndices: [Int]) {
        for index in tableIndices {
            self.detailCellAt(index: index)?.update()
        }
    }
    
    //
    // Mark: - Controller Delegates
    
    func shouldMakeNewTask() {
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
    
    func shouldAddTime(from first: Date, to final: Date) {
        guard let task = self.segueTask else {
            return
        }
        
        self.taskCollection.createDuration(for: task, from: first, to: final)
    }
    
    func shouldChangeNote(to note: String) {
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
        
    @objc func expand(recognizer: UITapGestureRecognizer) {
        guard let indexPath = self.tableView.indexPathForRow(at: recognizer.location(in: self.tableView)) else {
            return
        }
        
        if indexPath.section != 0 {
            return
        }
        
        self.taskCollection.toggleExpansion(index: self.taskCollection.taskIndex(tableIndex: indexPath.row))
    }
    
    @objc func edit(recognizer: UILongPressGestureRecognizer) {
        if recognizer.state != .began {
            return
        }
        
        let point = recognizer.location(in: self.tableView)
        
        guard let indexPath = self.tableView.indexPathForRow(at: point) else {
            return
        }
        
        let task = self.taskCollection.task(at: self.taskCollection.taskIndex(tableIndex: indexPath.row))
        
        let queueSegue = {
            self.segueTask = task
            self.performSegue(withIdentifier: "AddTime", sender: nil)
        }
        
        self.showActionSheet(actions: [
            "Rename Task": (.default,     { self.renameTask(task: task) }),
            "Add Time":    (.default,     { queueSegue() }),
            "Delete Task": (.destructive, { self.taskCollection.delete(task: task) }),
        ])
    }
    
    @objc func editDetail(recognizer: UILongPressGestureRecognizer) {
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
        
        let message = duration.active() ? "Note: An active task detail cannot be deleted." : nil
        let noteKey = duration.note == nil ? "Add note" : "Update note"
        
        var actions: [String: (UIAlertActionStyle, () -> ())] = [
            noteKey: (.default, {
                self.segueTask = task
                self.segueDurationIndex = revIndex
                self.performSegue(withIdentifier: "ChangeNote", sender: nil)
            }),
        ]
            
        if !duration.active() {
            actions["Delete"] = (.destructive, {
                self.taskCollection.delete(duration: duration, index: revIndex)
            })
        }
        
        self.showActionSheet(message: message, actions: actions)
    }
    
    private func showActionSheet(message: String? = nil, actions: [String: (UIAlertActionStyle, () -> ())]) {
        let controller = UIAlertController(title: nil, message: message, preferredStyle: .actionSheet)
        
        for (name, (style, fn)) in actions {
            controller.addAction(UIAlertAction(title: name, style: style, handler: { _ in fn() }))
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
        
        if segue.identifier == "AddTime" {
            guard let controller = controller as? AddTimeViewController else {
                return
            }
            
            if let task = self.segueTask {
                controller.task = task
                controller.durations = self.taskCollection.durations()
                controller.delegate = self
            }
        }
        
        if segue.identifier == "ChangeNote" {
            guard let controller = controller as? ChangeNoteViewController else {
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
    
    //
    // Mark: - Table View Delegate
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? TaskCell {
            cell.teardown()
        }
    }
    
    //
    // Mark: - Table View Cell Factories
    
    private func makeTaskCell(tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "task", for: indexPath)
        
        if let cell = cell as? TaskCell {
            let index = self.taskCollection.taskIndex(tableIndex: indexPath.row)
            
            cell.setup(task: self.taskCollection.task(at: index), index: index, delegate: self.taskCollection)
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
    
    //
    // Mark: - Cell Accessors
    
    func cellAt(index: Int) -> TaskCell? {
        return self.tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? TaskCell
    }
    
    func detailCellAt(index: Int) -> TaskDetailCell? {
        return self.tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? TaskDetailCell
    }
}
