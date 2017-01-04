//
//  Delegates.swift
//  Tally
//
//  Created by Eric Fritz on 1/2/17.
//  Copyright © 2017 Eric Fritz. All rights reserved.
//

import UIKit

// TODO - rename for matching verb tense

protocol TaskCollectionDelegate {
    func stopTask(index: Int)
    func updateTask(index: Int)
    func updateDetail(index: Int)
    func moveTaskCell(from: Int, to: Int)
    
    func addTaskCell(index: Int)
    func removeTaskCell(index: Int)
    
    func addDetailCells(indices: [Int])
    func removeDetailCells(indices: [Int])
}

protocol NewTaskDelegate {
    func makeNewTask()
}

protocol TimerStateChangedDelegate {
    func started(index: Int)
    func stopped(index: Int)
}

protocol TimeAddedDelegate {
    func addTime(first: Date, final: Date)
}

protocol NoteAddedDelegate {
    func editNote(note: String)
}
