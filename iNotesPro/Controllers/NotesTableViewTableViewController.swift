//
//  NotesTableViewTableViewController.swift
//  iNotesPro
//
//  Created by Nirmal Sumanth on 11/06/20.
//  Copyright © 2020 Nirmal Sumanth. All rights reserved.
//

import UIKit
import CoreData

class NotesTableViewTableViewController: UITableViewController {
    
    var notes = [Note]()
    var clickedNote: Note? = nil
    var clickedNoteIndex: Int? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(reloadTableView(_:)), name: NotificationConstants.noteCreated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadTableView(_:)), name: NotificationConstants.noteUpdated, object: nil)
        
    
        let fetchRequest: NSFetchRequest<Note> = Note.fetchRequest()
        do{
            self.notes = try PersistanceService.context.fetch(fetchRequest)
            self.tableView.reloadData()
        } catch{
            
        }

    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notes.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "activeNotesTableCell") as! NotesTableViewCell

        cell.noteCellTitle?.text = notes[indexPath.row].noteTitle
        cell.noteCellDescription?.text = notes[indexPath.row].noteDescription
        return cell
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        clickedNote = notes[indexPath.row]
        clickedNoteIndex = indexPath.row
        self.performSegue(withIdentifier: "activeNoteCellClicked", sender: self)


        
    }
    
    @objc func reloadTableView(_ notification: Notification){
        //load data here
        if let data = notification.userInfo as? [String: Note]
        {
            for (_, note) in data
            {
                notes.append(note)
            }
        }
        if let data = notification.userInfo as? [String: Any]
        {
            notes[data["index"] as! Int] = data["data"] as! Note
        }
        self.tableView.reloadData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.identifier == "activeNoteCellClicked"
        {
            let destination = segue.destination as? NoteViewController
            destination?.noteData = self.clickedNote
            destination?.noteIndex = self.clickedNoteIndex
        }
    }
}
