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
    
    var intactActiveNotesDataSource = [Note]()
    var originalSortedNotesDataSource = [Note]()
    var currentNotesDataSource = [Note]()
    var clickedNote: Note? = nil
    var clickedNoteIndex: Int? = nil
    var clickedInfoButtonIndex: Int? = nil
    let topOffset: CGFloat = 86
    var isActiveNotes = true
    
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

        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPress(_:)))
        self.view.addGestureRecognizer(longPressRecognizer)
        
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchContainerView.addSubview(searchController.searchBar)
        searchController.searchBar.delegate = self
    
        
        loadtableViewData()

    }
    func loadtableViewData(){
        let activeNotesFetchRequest: NSFetchRequest<Note> = Note.fetchRequest()
                activeNotesFetchRequest.predicate = NSPredicate(format: "isActive == %@", NSNumber(value: true) as! CVarArg)
                do{
                    self.intactActiveNotesDataSource = try PersistanceService.context.fetch(activeNotesFetchRequest)
                    self.currentNotesDataSource = self.intactActiveNotesDataSource
                    self.originalSortedNotesDataSource = self.currentNotesDataSource.sorted(by: { $0.createdAt!.compare($1.createdAt!) == .orderedDescending })
                    self.currentNotesDataSource = self.originalSortedNotesDataSource
                    self.tableView.reloadData()
                } catch{
                    
                }
        for note in currentNotesDataSource{
                print(note.audioAttachmentsArray.count)
            
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
        cell.noteCreatedDate?.text = currentNotesDataSource[indexPath.row].createdAt?.getFormattedDate(format: "MMM d, yy")
        //cell.layer.borderWidth = 0.5
        cell.layer.cornerRadius = 10
        cell.layer.masksToBounds = true
        //cell.layer.shadowOffset = CGSize(width: -1, height: 1)
//        cell.infoButtonAction = { sender in
//            // Do whatever you want from your button here.
//            self.clickedInfoButtonIndex = indexPath.row
//        }
        cell.infoButton.tag = indexPath.row
        
        return cell
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        clickedNote = currentNotesDataSource[indexPath.row]
        clickedNoteIndex = indexPath.row
        searchController.isActive = false
        self.performSegue(withIdentifier: "activeNoteCellClicked", sender: self)
    }

    //Called, when long press occurred
    @objc func longPress(_ longPressGestureRecognizer: UILongPressGestureRecognizer) {

        if longPressGestureRecognizer.state == UIGestureRecognizer.State.began {

            let touchPoint = longPressGestureRecognizer.location(in: self.view)
            if let indexPath = tableView.indexPathForRow(at: touchPoint) {
                showOptionsAlertController(indexPath: indexPath)
            }
        }
    }
    func showOptionsAlertController(indexPath: IndexPath) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            
        // 2
        let deleteAction = UIAlertAction(title: "Delete", style: .default) { (action) in
            self.deleteNoteHandler(indexPath: indexPath)
        }
        // 3
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
            
        // 4
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
            
        // 5
        self.present(alert, animated: true, completion: nil)
    }
    func deleteNoteHandler(indexPath: IndexPath){
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Note")
        fetchRequest.predicate = NSPredicate(format: "noteID = %@", originalSortedNotesDataSource[indexPath.row].noteID!)

        do{
        let fetchResults = try PersistanceService.context.fetch(fetchRequest)
            if fetchResults.count != 0 {
                let managedObject: Note = fetchResults[0] as! Note
                PersistanceService.context.delete(managedObject)
                    
                do {
                    try PersistanceService.context.save()
                }
                catch {
                        
                }
                //originalSortedNotesDataSource[indexPath.row].isActive = false
                originalSortedNotesDataSource.remove(at: indexPath.row)
                currentNotesDataSource = originalSortedNotesDataSource
                self.tableView.reloadData()
            }
            
        } catch{
            
        }
    }
    @objc func reloadTableView(_ notification: Notification){
        //load
        
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
            print(currentNotesDataSource[indexInOriginalDataSource!].audioAttachmentsArray.count)
            //currentNotesDataSource[data!["index"] as! Int] = data!["data"] as! Note
            self.tableView.reloadData()
        case NotificationConstants.iNotesTabBarItemTapped:
            if isActiveNotes{
                self.tableView.scrollRectToVisible(searchController.searchBar.frame, animated: true)
            }
            else{
                self.isActiveNotes = true
                self.loadtableViewData()
                self.tableView.reloadData()
            }
            
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
        if segue.identifier == "infoPopover"
        {
            let destination = segue.destination as? InfoPopoverViewController
            destination?.note = self.currentNotesDataSource[(sender as! UIButton).tag]
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
            currentNotesDataSource = originalSortedNotesDataSource
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

extension Date {
    func getFormattedDate(format: String) -> String {
         let dateformat = DateFormatter()
         dateformat.dateFormat = format
         return dateformat.string(from: self)
     }
}
