//
//  Delegates.swift
//  Tally
//
//  Created by Eric Fritz on 1/2/17.
//  Copyright © 2017 Eric Fritz. All rights reserved.
//

import UIKit

protocol TaskCollectionDelegate {
    func stopTaskCell(at: Int)
    func moveTaskCell(from: Int, to: Int)
    func moveDetailCell(index: Int, up: Bool)
    
    func insertTaskCell(at: Int)
    func deleteTaskCell(at: Int)
    func updateTaskCell(at: Int)
    
    func insertDetailCells(at: [Int])
    func deleteDetailCells(at: [Int])
    func reloadDetailCells(at: [Int])
    func updateDetailCells(at: [Int])
}

protocol TimerStateChangedDelegate {
    func timer(started index: Int, running: Bool)
    func timer(stopped index: Int)
}

protocol NewTaskDelegate {
    func shouldMakeNewTask()
}

protocol TimeAddedDelegate {
    func shouldAddTime(from: Date, to: Date)
}

protocol NoteChangedDelegate {
    func shouldChangeNote(to: String)
}
