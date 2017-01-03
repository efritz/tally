//
//  Delegates.swift
//  Tally
//
//  Created by Eric Fritz on 1/2/17.
//  Copyright © 2017 Eric Fritz. All rights reserved.
//

import UIKit

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
