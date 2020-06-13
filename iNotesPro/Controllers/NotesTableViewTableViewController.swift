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

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(reloadTableView(_:)), name: NSNotification.Name(rawValue: "noteCreated"), object: nil)
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
//        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "activeNotesTableCell")
        let cell = tableView.dequeueReusableCell(withIdentifier: "activeNotesTableCell") as! NotesTableViewCell

        cell.noteCellTitle?.text = notes[indexPath.row].noteTitle
        cell.noteCellDescription?.text = notes[indexPath.row].noteDescription
        return cell
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
        self.tableView.reloadData()
    }

}
