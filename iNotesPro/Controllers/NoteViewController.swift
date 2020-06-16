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
    @IBOutlet weak var selectImageBtn: UIButton!
    @IBOutlet weak var imageScrollView: UIScrollView!
    @IBOutlet weak var titleAndDescriptionVIew: UIView!
    var locationString = ""
    var noteData: Note? = nil
    var attachmentData: Attachments? = nil
    var noteIndex: Int? = nil
    let imageWidth: CGFloat = 398
    var xPosition: CGFloat = 0
    var scrollViewContentWidth: CGFloat = 0
    
    var addedImages = [UIImage]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        setupView()
    }
    
    func setupView(){
        noteDescription.delegate = self
        if(noteData != nil){
            setupViewItems()
        }
        else{
            setupLocationManager()
        }
    }
    func setupViewItems(){
        noteTitle.text = noteData?.noteTitle
        noteDescription.text = noteData?.noteDescription
        for attachment in noteData!.attachmentsArray {
            handleImage(image: UIImage(data: attachment.attachmentBinary!)!, imageTag: TagConstants.savedImage)
        }
        
        
    }
    func setupLocationManager(){
        self.locationManager.requestAlwaysAuthorization()

        // For use in foreground
        self.locationManager.requestWhenInUseAuthorization()

        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.requestLocation()
        }
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
    

    @IBAction func selectImageClicked(_ sender: UIButton) {
        showChooseSourceTypeAlertController()
    }
    
    
    @IBAction func noteSave(_ sender: UIBarButtonItem) {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Note")
        fetchRequest.predicate = NSPredicate(format: "noteID = %@", noteData?.noteID! as! CVarArg)

        do{
        let fetchResults = try PersistanceService.context.fetch(fetchRequest)
            if fetchResults.count != 0 {
                let managedObject: Note = fetchResults[0] as! Note
                noteData?.noteTitle = noteTitle.text!
                noteData?.noteDescription = noteDescription.text!
                managedObject.setValue(noteTitle.text!, forKey: "noteTitle")
                managedObject.setValue(noteDescription.text!, forKey: "noteDescription")

                let images = imageScrollView.subviews.filter{ ($0 is UIImageView) }
                let imagesToSave = images.filter{ ($0 as! UIImageView).tag == TagConstants.pickedImage }
                print (imagesToSave.count)
                if imagesToSave.count > 0 {
                    for image in imagesToSave {
                        print((image as! UIImageView).tag)
                        let attachment = Attachments(context: PersistanceService.context)
                        attachment.attachmentID = UUID().uuidString
                        attachment.noteID = noteData!.noteID
                        attachment.attachmentBinary = (image as! UIImageView).image!.jpegData(compressionQuality: 1.0)
                        attachment.createdAt = Date()
                        attachment.updatedAt = Date()
                        attachment.attachmentType = AttachmentConstants.image
                        noteData!.addToAttachments(attachment)
                    }
                }
                    
                do {
                    try PersistanceService.context.save()
                }
                catch {
                        
                }
                let notificationPayload = ["data": noteData!, "index": noteIndex!] as [String : Any]
                NotificationCenter.default.post(name: NotificationConstants.noteUpdated, object: self, userInfo: notificationPayload)
                navigationController?.popViewController(animated: true)
            }
            
        } catch{
            
        }
    }
    @IBAction func noteDone(_ sender: UIBarButtonItem) {
        let title = noteTitle.text
        let description = noteDescription.text
        print (title!)
        print(description!)
        print(locationString)
        
        if (title != "" || description != ""){
            //Note table row insertion
            let note = Note(context: PersistanceService.context)
            note.noteID = UUID().uuidString
            note.noteTitle = noteTitle.text!
            note.noteDescription = noteDescription.text!
            note.createdAt = Date()
            note.updatedAt = Date()
            note.location = locationString
            
            //Attachment table row insertion
            let imagesToSave = imageScrollView.subviews.filter{ ($0 is UIImageView) }
            print (imagesToSave.count)
            if imagesToSave.count > 0 {
                for image in imagesToSave {
                    print((image as! UIImageView).tag)
                    let attachment = Attachments(context: PersistanceService.context)
                    attachment.attachmentID = UUID().uuidString
                    attachment.noteID = note.noteID
                    attachment.attachmentBinary = (image as! UIImageView).image!.jpegData(compressionQuality: 1.0)
                    attachment.createdAt = Date()
                    attachment.updatedAt = Date()
                    attachment.attachmentType = AttachmentConstants.image
                    note.addToAttachments(attachment)
                }
                
            }
                        
            PersistanceService.saveContext()
            print("Saved")
            let notificationPayload = ["data": note]
            NotificationCenter.default.post(name: NotificationConstants.noteCreated, object: self, userInfo: notificationPayload)

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

extension NoteViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    
    
    func showChooseSourceTypeAlertController() {
        let alert = UIAlertController(title: "Select source", message: nil, preferredStyle: .actionSheet)
            
        // 2
        let deleteAction = UIAlertAction(title: "Choose a Photo", style: .default) { (action) in
            self.showImagePickerController(sourceType: .photoLibrary)
        }
        let saveAction = UIAlertAction(title: "Take a New Photo", style: .default) { (action) in
            self.showImagePickerController(sourceType: .camera)
        }
            
        // 3
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
            
        // 4
        alert.addAction(deleteAction)
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
            
        // 5
        self.present(alert, animated: true, completion: nil)
    }
    
    func showImagePickerController(sourceType: UIImagePickerController.SourceType) {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        //imagePickerController.allowsEditing = true
        imagePickerController.sourceType = sourceType
        present(imagePickerController, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let editedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            self.handleImage(image: editedImage, imageTag: TagConstants.pickedImage)
        } else if let originalImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            self.handleImage(image: originalImage, imageTag: TagConstants.pickedImage)
        }
        dismiss(animated: true, completion: nil)
    }
    
    func handleImage(image: UIImage, imageTag: Int){
        let imageView = UIImageView(image: image)
        imageView.frame = CGRect(x: 0, y: 0, width: 398, height: 188)
        var scale: CGFloat = 1
        if image.size.width > image.size.height {
            scale = imageView.frame.width / image.size.width
        } else {
            scale = imageView.frame.height / image.size.height
        }
        imageView.frame.size = CGSize(width: image.size.width * scale, height: image.size.height * scale)

        imageView.contentMode = UIView.ContentMode.scaleAspectFit
        imageView.frame.origin.x = xPosition
        imageView.frame.origin.y = 10
        imageView.tag = imageTag
        let spacer: CGFloat = 10
        xPosition = xPosition + imageView.frame.width + spacer
               
        
        
        let frame1 = CGRect(x: xPosition, y: 10, width: 50, height: imageScrollView.frame.height )
        let addBtn = UIButton(frame: frame1)
        
        
        let boldConfig = UIImage.SymbolConfiguration(weight: .bold)
        let boldSearch = UIImage(systemName: "plus", withConfiguration: boldConfig)
        addBtn.frame.origin.x = xPosition
        addBtn.frame.origin.y = 10
        
        
//        xPosition = xPosition + addBtn.frame.width + spacer
        addBtn.setImage(boldSearch, for: .normal)
        addBtn.backgroundColor = UIColor.systemBackground
        
        //tag is set to 1 if it is add image button
        addBtn.tag = TagConstants.addImageBtn
        
        scrollViewContentWidth = scrollViewContentWidth + imageView.frame.width + addBtn.frame.width + spacer
        imageScrollView.contentSize = CGSize(width: scrollViewContentWidth, height: 188)
        let prevAddBtn = imageScrollView.viewWithTag(TagConstants.addImageBtn) as? UIButton
        prevAddBtn?.removeTarget(self, action: #selector(selectImageClicked), for: .touchUpInside)
        prevAddBtn?.removeFromSuperview()
        addBtn.addTarget(self, action: #selector(selectImageClicked), for: .touchUpInside)

        imageScrollView.addSubview(imageView)
        imageScrollView.addSubview(addBtn)
        //removing previously added button scroll width
        scrollViewContentWidth = scrollViewContentWidth - addBtn.frame.width
        addedImages.append(image)
    }
}
