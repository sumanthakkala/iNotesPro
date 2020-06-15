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
    
    var intactNotesDataSource = [Note]()
    var originalSortedNotesDataSource = [Note]()
    var currentNotesDataSource = [Note]()
    var clickedNote: Note? = nil
    var clickedNoteIndex: Int? = nil
    let topOffset: CGFloat = 86
    
    let sortByDate = 0
    let sortByTitle = 1
    var selectedSortMode = 0

    @IBOutlet weak var searchContainerView: UIView!
    @IBOutlet weak var sortBtn: UIBarButtonItem!
    var searchController: UISearchController!
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(reloadTableView(_:)), name: NotificationConstants.noteCreated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadTableView(_:)), name: NotificationConstants.noteUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadTableView(_:)), name: NotificationConstants.iNotesTabBarItemTapped, object: nil)

        
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchContainerView.addSubview(searchController.searchBar)
        searchController.searchBar.delegate = self
    
        let fetchRequest: NSFetchRequest<Note> = Note.fetchRequest()
        do{
            self.intactNotesDataSource = try PersistanceService.context.fetch(fetchRequest)
            self.currentNotesDataSource = self.intactNotesDataSource
            self.originalSortedNotesDataSource = self.currentNotesDataSource.sorted(by: { $0.createdAt!.compare($1.createdAt!) == .orderedDescending })
            self.currentNotesDataSource = self.originalSortedNotesDataSource
            self.tableView.reloadData()
        } catch{
            
        }

    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentNotesDataSource.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "activeNotesTableCell") as! NotesTableViewCell

        cell.noteCellTitle?.text = currentNotesDataSource[indexPath.row].noteTitle
        cell.noteCellDescription?.text = currentNotesDataSource[indexPath.row].noteDescription
        return cell
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        clickedNote = currentNotesDataSource[indexPath.row]
        clickedNoteIndex = indexPath.row
        searchController.isActive = false
        self.performSegue(withIdentifier: "activeNoteCellClicked", sender: self)
    }

    @objc func reloadTableView(_ notification: Notification){
        //load data here
        switch notification.name {
        case NotificationConstants.noteCreated:
            let data = notification.userInfo as? [String: Note]
            for (_, note) in data!
            {
                currentNotesDataSource = originalSortedNotesDataSource
                originalSortedNotesDataSource.append(note)
                currentNotesDataSource.append(note)
            }
            //self.tableView.reloadData()
            self.reloadDataBySelectedSortMode()
        case NotificationConstants.noteUpdated:
            let data = notification.userInfo as? [String: Any]
            let indexInOriginalDataSource = originalSortedNotesDataSource.firstIndex(of: clickedNote!)
            currentNotesDataSource = originalSortedNotesDataSource
            currentNotesDataSource[indexInOriginalDataSource!] = data!["data"] as! Note
            //currentNotesDataSource[data!["index"] as! Int] = data!["data"] as! Note
            self.tableView.reloadData()
        case NotificationConstants.iNotesTabBarItemTapped:
            self.tableView.scrollRectToVisible(searchController.searchBar.frame, animated: true)
        default:
            self.tableView.reloadData()
        }
        
        
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
    
    @IBAction func sortClicked(_ sender: UIBarButtonItem) {
        if sender.tag == sortByDate {
            sender.tag = sortByTitle
            sender.image = UIImage(named: "sortByTitle")
            self.selectedSortMode = sortByTitle
        }
        else{
            sender.tag = sortByDate
            sender.image = UIImage(named: "sortByDate")
            self.selectedSortMode = sortByDate
        }
        self.reloadDataBySelectedSortMode()
    }
    
    func reloadDataBySelectedSortMode() {
        if selectedSortMode == sortByDate{
            self.originalSortedNotesDataSource = self.currentNotesDataSource.sorted(by: { $0.createdAt!.compare($1.createdAt!) == .orderedDescending })
            self.currentNotesDataSource = self.originalSortedNotesDataSource
            self.tableView.reloadData()
        }
        else{
            self.currentNotesDataSource.sort(by: { $0.noteTitle!.lowercased() < $1.noteTitle!.lowercased() })
            self.originalSortedNotesDataSource = self.currentNotesDataSource
            self.tableView.reloadData()
        }
    }
    
    func filterCurrentDataSource(searchTerm: String) {
        if searchTerm.count > 0 {
            //currentNotesDataSource = originalNotesDataSource
            let filteredNotes = currentNotesDataSource.filter{ ($0.noteTitle?.replacingOccurrences(of: " ", with: "").lowercased().contains(searchTerm.replacingOccurrences(of: " ", with: "").lowercased()))!
                ||
                ($0.noteDescription?.replacingOccurrences(of: " ", with: "").lowercased().contains(searchTerm.replacingOccurrences(of: " ", with: "").lowercased()))!
            }
            currentNotesDataSource = filteredNotes
            self.tableView.reloadData()
        }
    }
    func restoreCurrentDataSource(){
        currentNotesDataSource = originalSortedNotesDataSource
        self.tableView.reloadData()
    }
}


extension NotesTableViewTableViewController: UISearchResultsUpdating{
    func updateSearchResults(for searchController: UISearchController) {
        if let searchText = searchController.searchBar.text {
            filterCurrentDataSource(searchTerm: searchText)
        }
    }
    
    
}

extension NotesTableViewTableViewController: UISearchBarDelegate{
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchController.isActive = false
        if let searchText = searchBar.text {
            filterCurrentDataSource(searchTerm: searchText)
        }
    }
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchController.isActive = false
//        if let searchText = searchBar.text, !searchText.isEmpty {
//            restoreCurrentDataSource()
//        }
        restoreCurrentDataSource()
    }
}
