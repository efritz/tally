//
//  AddNoteViewController.swift
//  Tally
//
//  Created by Eric Fritz on 12/28/16.
//  Copyright © 2016 Eric Fritz. All rights reserved.
//

import UIKit

class AddNoteViewController: UIViewController {
    @IBOutlet weak var navItem: UINavigationItem!
    @IBOutlet weak var textView: UITextView!
    
    var duration: Duration? {
        didSet {
            self.configureView()
        }
    }
    
    var delegate: NoteAddedDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureView()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // Mark: - Layout view
    
    private func configureView() {
        guard let duration = self.duration, self.textView != nil else {
            return
        }
        
        // Set title
        self.navItem.title = "Task \(duration.task.name)"
        
        // Set previous text
        self.textView.text = duration.note ?? ""
    }
    
    // Mark: - Dismissing
    
    @IBAction func onCancel(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onDone(_ sender: UIBarButtonItem) {
        self.delegate?.editNote(note: self.textView.text)
        self.dismiss(animated: true, completion: nil)
    }
}
