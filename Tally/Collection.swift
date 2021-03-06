        //
//  Collection.swift
//  Tally
//
//  Created by Eric Fritz on 1/2/17.
//  Copyright © 2017 Eric Fritz. All rights reserved.
//

import UIKit

class TaskCollection: TimerStateChangedDelegate {
    private var tasks: [TimedTask]
    private var activeIndex: Int?
    private var expandedIndex: Int?
    private var timer: Timer?
    
    var delegate: TaskCollectionDelegate?
    
    class func load() ->TaskCollection {
        if let tasks = Database.instance.allTasks() {
            return TaskCollection(tasks: tasks)
        }
        
        // better recovery
        print("Could not retrieve tasks.")
        
        return TaskCollection(tasks: [])
    }
    
    private init(tasks: [TimedTask]) {
        self.tasks = tasks
    }
    
    //
    // Mark: - Getters
    
    func task(at index: Int) -> TimedTask {
        return self.tasks[index]
    }
    
    func active() -> (Int, TimedTask)? {
        if let activeIndex = self.activeIndex {
            return (activeIndex, self.tasks[activeIndex])
        }
        
        return nil
    }
    
    func expanded() -> (Int, TimedTask)? {
        if let expandedIndex = self.expandedIndex {
            return (expandedIndex, self.tasks[expandedIndex])
        }
        
        return nil
    }
    
    func index(of task: TimedTask) -> Int? {
        return self.tasks.index(where: { $0.id == task.id })
    }
    
    func elapsed() -> Int {
        return self.tasks.reduce(0, { (a, b) in a + b.elapsed() })
    }
    
    func durations() -> [Duration] {
        return self.tasks.flatMap({ $0.durations }).sorted(by: { a, b in a.first < b.first })
    }
    
    //
    // Mark: - Task Creation and Deletion
    
    func createTask(named name: String) {
        guard let task = Database.instance.createTask(name: name) else {
            // better recovery
            print("Could not create task.")
            return
        }

        self.tasks.append(task)
        self.delegate?.insertTaskCell(at: self.tableIndex(taskIndex: self.tasks.count - 1))
    }
    
    func delete(task: TimedTask) {
        guard let taskIndex = self.index(of: task) else {
            return
        }
        
        if !Database.instance.delete(task: task) {
            // better recovery
            print("Task could not be deleted.")
            return
        }
        
        if task.active() {
            self.activeIndex = nil
        }
        
        if let activeIndex = self.activeIndex {
            if activeIndex > taskIndex {
                self.activeIndex = activeIndex - 1
            }
        }
        
        if let expandedIndex = self.expandedIndex, expandedIndex == taskIndex {
            let _ = self.collapse()
        }
        
        self.tasks.remove(at: taskIndex)
        self.delegate?.deleteTaskCell(at: self.tableIndex(taskIndex: taskIndex))
    }
    
    //
    // Mark: - Duration Creation and Deletion
    
    func createDuration(for task: TimedTask, from first: Date, to final: Date) {
        guard let duration = Database.instance.createDuration(for: task, first: first, final: final) else {
            // better recovery
            print("Could not create task detail.")
            return
        }
        
        var index = 0
        while index < task.durations.count && first >= task.durations[index].first {
            index = index + 1
        }
        
        guard let taskIndex = self.index(of: task) else {
            return
        }
        
        for i in index..<task.durations.count {
            self.delegate?.moveDetailCell(index: taskIndex + task.durations.count - i, up: true)
        }
        
        task.durations.insert(duration, at: index)
        
        if let expandedIndex = self.expandedIndex {
            if expandedIndex == taskIndex {
                let tableIndex = taskIndex + task.durations.count - index
                
                if task.durations.count == 1 {
                    self.delegate?.reloadDetailCells(at: [tableIndex])
                } else {
                    self.delegate?.insertDetailCells(at: [tableIndex])
                }
            }
        }
        
        self.delegate?.updateTaskCell(at: self.tableIndex(taskIndex: taskIndex))
        self.reorder(index: taskIndex)
    }
    
    func delete(duration: Duration, index: Int) {
        guard let (taskIndex, task) = self.expanded() else {
            return
        }
        
        if !Database.instance.delete(duration: duration) {
            // better recovery
            print("Could not delete duration.")
            return
        }
        
        let tableIndex = taskIndex + task.durations.count - index
        
        for i in index..<task.durations.count {
            self.delegate?.moveDetailCell(index: taskIndex + task.durations.count - i, up: false)
        }
        
        task.durations.remove(at: index)
        
        if task.durations.count == 0 {
            self.delegate?.reloadDetailCells(at: [tableIndex])
        } else {
            self.delegate?.deleteDetailCells(at: [tableIndex])
        }
        
        self.delegate?.updateTaskCell(at: self.tableIndex(taskIndex: taskIndex))
        self.reorder(index: taskIndex)
    }
    
    //
    // Mark: - Start/Stop and Update
    
    func start(index: Int, running: Bool = false) {
        if self.activeIndex != index {
            if !running {
                self.stop()
                self.tasks[index].start()
            
                if let expandedIndex = self.expandedIndex {
                    if expandedIndex == index {
                        if self.tasks[index].durations.count == 1 {
                            self.delegate?.reloadDetailCells(at: [index + 1])
                        } else {
                            self.delegate?.insertDetailCells(at: [index + 1])
                        }
                    }
                }
            }
            
            self.activeIndex = index
        }
        
        if self.timer == nil {
            self.timer = Timer.scheduledTimer(withTimeInterval: 0.33, repeats: true) { _ in
                self.update()
            }
        }
    }
    
    func stop() {
        guard let activeIndex = self.activeIndex else {
            return
        }
        
        self.delegate?.stopTaskCell(at: self.tableIndex(taskIndex: activeIndex))
        
        self.tasks[activeIndex].stop()
        self.update()
        self.activeIndex = nil
        self.timer?.invalidate()
        self.timer = nil
    }
    
    private func update() {
        guard let activeIndex = self.activeIndex else {
            return
        }
        
        delegate?.updateTaskCell(at: self.tableIndex(taskIndex: activeIndex))
        
        if let expandedIndex = self.expandedIndex {
            if expandedIndex == activeIndex {
                delegate?.updateDetailCells(at: [self.tableIndex(taskIndex: activeIndex) + 1])
            }
        }
        
        self.activeIndex = self.reorderUp(index: activeIndex)
    }
    
    //
    // Mark: - Expansion
    
    func toggleExpansion(index: Int) {
        if let expandedIndex = self.collapse() {
            if expandedIndex == index {
                return
            }
        }
        
        self.expand(index: index)
    }
    
    private func expand(index: Int) {
        self.expandedIndex = index
        delegate?.insertDetailCells(at: self.detailIndices())
    }
    
    private func collapse() -> Int? {
        guard let expandedIndex = self.expandedIndex else {
            return nil
        }
        
        let indices = self.detailIndices()
        self.expandedIndex = nil
        delegate?.deleteDetailCells(at: indices)
        return expandedIndex
    }
    
    //
    // Mark: - Ordering
    
    func reorder(index: Int) {
        for f in [self.reorderUp, self.reorderDown] {
            let newIndex = f(index)
            
            if newIndex != index {
                if let activeIndex = self.activeIndex, activeIndex == index {
                    self.activeIndex = newIndex
                }
                
                return
            }
        }
    }
    
    private func reorderUp(index: Int) -> Int {
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
            return index
        }
        
        var shouldExpand: Int? = nil
        if let expandedIndex = self.expandedIndex {
            if newIndex <= expandedIndex && expandedIndex <= index {
                let _ = self.collapse()
                
                if expandedIndex == index {
                    shouldExpand = newIndex
                } else {
                    shouldExpand = expandedIndex + 1
                }
            }
        }
        
        for i in (newIndex..<index).reversed() {
            self.swapTasks(i, i + 1)
        }
        
        delegate?.moveTaskCell(from: self.tableIndex(taskIndex: index), to: self.tableIndex(taskIndex: newIndex))
        
        if let shouldExpand = shouldExpand {
            self.expand(index: shouldExpand)
        }
        
        return newIndex
    }
    
    private func reorderDown(index: Int) -> Int {
        var newIndex = index
        while newIndex < self.tasks.count - 1 {
            let a = self.tasks[index].elapsed()
            let b = self.tasks[newIndex + 1].elapsed()
            
            if !compareElapsed(b, a) {
                break
            }
            
            newIndex = newIndex + 1
        }
        
        if index == newIndex {
            return index
        }
        
        var shouldExpand: Int? = nil
        if let expandedIndex = self.expandedIndex {
            if index <= expandedIndex && expandedIndex <= newIndex {
                let _ = self.collapse()
                
                if expandedIndex == index {
                    shouldExpand = newIndex
                } else {
                    shouldExpand = expandedIndex - 1
                }
            }
        }
        
        for i in (index+1)...newIndex {
            self.swapTasks(i, i - 1)
        }
        
        delegate?.moveTaskCell(from: self.tableIndex(taskIndex: index), to: self.tableIndex(taskIndex: newIndex))
        
        if let shouldExpand = shouldExpand {
            self.expand(index: shouldExpand)
        }
        
        return newIndex
    }
    
    private func swapTasks(_ i: Int, _ j: Int) {
        let t = self.tasks[j]
        self.tasks[j] = self.tasks[i]
        self.tasks[i] = t
    }
    
    //
    // Mark: - Index Calculators
    
    func numberOfCells() -> Int {
        if let expandedIndex = self.expandedIndex {
            return self.tasks.count + self.numberOfDetailCellsFor(index: expandedIndex)
        }
        
        return self.tasks.count
    }
    
    func detailIndices() -> [Int] {
        if let expandedIndex = self.expandedIndex {
            return (0..<self.numberOfDetailCellsFor(index: expandedIndex)).map({ expandedIndex + $0 + 1 })
        }
        
        return []
    }
    
    func numberOfDetailCellsFor(index: Int) -> Int {
        return max(1, self.tasks[index].durations.count)
    }
    
    func taskIndex(tableIndex: Int) -> Int {
        if let expandedIndex = self.expandedIndex {
            if expandedIndex < tableIndex {
                return tableIndex - self.numberOfDetailCellsFor(index: expandedIndex)
            }
        }
        
        return tableIndex
    }
    
    private func tableIndex(taskIndex: Int) -> Int {
        if let expandedIndex = self.expandedIndex {
            if expandedIndex < taskIndex{
                return taskIndex + self.numberOfDetailCellsFor(index: expandedIndex)
            }
        }
        
        return taskIndex
    }
    
    //
    // Mark: - Timer State Changed Delegates
    
    func timer(started index: Int, running: Bool) {
        self.start(index: index, running: running)
    }
    
    func timer(stopped index: Int) {
        self.stop()
    }
}
