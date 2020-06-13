//
//  NoteViewController.swift
//  iNotesPro
//
//  Created by Nirmal Sumanth on 11/06/20.
//  Copyright © 2020 Nirmal Sumanth. All rights reserved.
//

import UIKit
import CoreData
import CoreLocation

class NoteViewController: UIViewController, CLLocationManagerDelegate, UITextViewDelegate {
    let locationManager = CLLocationManager()

    @IBOutlet weak var noteTitle: UITextField!
    @IBOutlet weak var noteDescription: UITextView!
    var locationString = ""
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.locationManager.requestAlwaysAuthorization()

        // For use in foreground
        self.locationManager.requestWhenInUseAuthorization()

        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.requestLocation()
        }
        
        noteDescription.delegate = self
        noteDescription.text = "Take a note..."
        noteDescription.textColor = UIColor.lightGray
    }
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == UIColor.lightGray {
            textView.text = nil
            textView.textColor = UIColor.black
        }
    }
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "Take a note..."
            textView.textColor = UIColor.lightGray
        }
    }
    

    @IBAction func noteSave(_ sender: UIBarButtonItem) {
    }
    @IBAction func noteDone(_ sender: UIBarButtonItem) {
        let title = noteTitle.text
        let description = noteDescription.text
        print (title!)
        print(description!)
        print(locationString)
        
        if (title != "" || description != ""){
            let note = Note(context: PersistanceService.context)
            note.noteID = UUID().uuidString
            note.noteTitle = noteTitle.text!
            note.noteDescription = noteDescription.text!
            note.createdAt = Date()
            note.updatedAt = Date()
            note.location = locationString
            
            PersistanceService.saveContext()
            print("Saved")
            let notificationPayload = ["data": note]
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "noteCreated"), object: self, userInfo: notificationPayload)

            self.dismiss(animated: true, completion: nil)
        }
        else{
            self.dismiss(animated: true, completion: nil)
        }
        
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        print("locations = \(locValue.latitude) \(locValue.longitude)")
        self.locationString = "\(locValue.latitude) \(locValue.longitude)"
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to find user's location: \(error.localizedDescription)")
    }
}
