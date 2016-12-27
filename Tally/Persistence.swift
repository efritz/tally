//
//  Persistence.swift
//  Tally
//
//  Created by Eric Fritz on 12/23/16.
//  Copyright © 2016 Eric Fritz. All rights reserved.
//

import UIKit
import SQLite

class Database {
    static let instance = Database()
    
    private let db: Connection?
    
    private let tasks = Table("tasks")
    private let durations = Table("durations")
    private let taskId = Expression<Int64>("taskId")
    private let durationId = Expression<Int64>("durationId")
    private let name = Expression<String>("name")
    private let first = Expression<Date>("first")
    private let final = Expression<Date?>("final")
    private let note = Expression<String?>("note")

    private init() {
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        
        do {
            db = try Connection("\(path)/tally.sqlite3")
        } catch let ex {
            db = nil
            print("Unable to open database (\(ex))")
        }
        
        do {
            try db!.run(tasks.create(temporary: false, ifNotExists: true, block: { table in
                table.column(self.taskId, primaryKey: true)
                table.column(self.name)
            }))
            
            try db!.run(durations.create(temporary: false, ifNotExists: true, block: { table in
                table.column(self.durationId, primaryKey: true)
                table.column(self.taskId, references: self.tasks, self.taskId)
                table.column(self.first)
                table.column(self.final)
                table.column(self.note)
            }))
        } catch let ex {
            print("Unable to create table (\(ex))")
        }
    }
    
    func allTasks() -> [TimedTask]? {
        if let db = self.db, let rows = try? db.prepare(self.tasks) {
            var results = [TimedTask]()
            for row in rows {
                let task = TimedTask(id: row[self.taskId], name: row[self.name], durations: [], color: makeRandomColor(mix: UIColor.white))
                
                if let durations = self.durations(for: task) {
                    for duration in durations {
                        task.durations.append(duration)
                    }
                } else {
                    return nil
                }
                
                results.append(task)
            }
            
            return results.sorted { $0.elapsed() >= $1.elapsed() }
        }
    
        return nil
    }
    
    func durations(for task: TimedTask) -> [Duration]? {
        let query = self.durations.filter(self.taskId == task.id)
        
        if let db = self.db, let rows = try? db.prepare(query) {
            var results = [Duration]()
            for row in rows {
                results.append(Duration(id: row[self.durationId], task: task, first: row[self.first], final: row[self.final], note: row[self.note]))
            }
            
            return results.sorted { $0.first <= $1.first }
        }
        
        return nil
    }
    
    func createTask(name: String) -> TimedTask? {
        let insert = self.tasks.insert(self.name <- name)
        
        if let db = self.db {
            if let id = try? db.run(insert) {
                return TimedTask(id: id, name: name, color: makeRandomColor(mix: UIColor.white))
            }
        }
        
        return nil
    }
    
    func update(task: TimedTask, name: String) -> Bool {
        let update = self.tasks.filter(self.taskId == task.id).update(self.name <- name)
        
        if let db = self.db {
            if let _ = try? db.run(update) {
                task.name = name
                return true
            }
        }
        
        return false
    }
    
    func delete(task: TimedTask) -> Bool {
        let deletions = [
            self.tasks.filter(self.taskId == task.id).delete(),
            self.durations.filter(self.taskId == task.id).delete()
        ]
        
        if let db = self.db {
            for query in deletions {
                if (try? db.run(query)) == nil {
                    return false
                }
            }
            
            return true
        }
        
        return false
    }
    
    func createDuration(for task: TimedTask) -> Duration? {
        return self.createDuration(for: task, first: Date())
    }
    
    func createDuration(for task: TimedTask, first: Date, final: Date? = nil) -> Duration? {
        let insert = self.durations.insert(self.taskId <- task.id, self.first <- first, self.final <- final)
        
        if let db = self.db {
            if let id = try? db.run(insert) {
                return Duration(id: id, task: task, first: first, final: final)
            }
        }
        
        return nil
    }
    
    func update(duration: Duration) -> Bool {
        let final = Date()
        let update = self.durations.filter(self.durationId == duration.id).update(self.final <- final)
        
        if let db = self.db {
            if let _ = try? db.run(update) {
                duration.final = final
                return true
            }
        }
        
        return false
    }
    
    func update(duration: Duration, withNote note: String) -> Bool {
        let update = self.durations.filter(self.durationId == duration.id).update(self.note <- note)
        
        if let db = self.db {
            if let _ = try? db.run(update) {
                duration.note = note
                return true
            }
        }
        
        return false
    }
    
    func delete(duration: Duration) -> Bool {
        if let db = self.db {
            if let _ = try? db.run(self.durations.filter(self.durationId == duration.id).delete()) {
                return true
            }
        }
        
        return false
    }
}
