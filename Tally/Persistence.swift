//
//  Persistence.swift
//  Tally
//
//  Created by Eric Fritz on 12/23/16.
//  Copyright © 2016 Eric Fritz. All rights reserved.
//

import SQLite
import Foundation

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
            }))
        } catch let ex {
            print("Unable to create table (\(ex))")
        }
    }
    
    func allTasks() -> [TimedTask]? {
        if let db = self.db, let rows = try? db.prepare(self.tasks) {
            var results = [TimedTask]()
            for row in rows {
                if let durations = self.durationsFor(taskId: row[self.taskId]) {
                    results.append(TimedTask(id: row[self.taskId], name: row[self.name], durations: durations))
                }
            }
            
            // TODO - sort
            return results
        }
    
        return nil
    }
    
    func durationsFor(taskId: Int64) -> [Duration]? {
        let query = self.durations.filter(self.taskId == taskId)
        
        if let db = self.db, let rows = try? db.prepare(query) {
            var results = [Duration]()
            for row in rows {
                results.append(Duration(id: row[self.durationId], first: row[self.first], final: row[self.final]))
            }
            
            // TODO - sort
            return results
        }
        
        return nil
    }
    
    func createTask(name: String) -> TimedTask? {
        let insert = self.tasks.insert(self.name <- name)
        
        if let db = self.db {
            if let id = try? db.run(insert) {
                return TimedTask(id: id, name: name)
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
        let first = Date()
        let insert = self.durations.insert(self.taskId <- task.id, self.first <- first)
        
        if let db = self.db {
            if let id = try? db.run(insert) {
                return Duration(id: id, first: first)
            }
        }
        
        return nil
    }
    
    func updateDuration(duration: Duration) -> Bool {
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
}
