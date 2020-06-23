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
import Lottie
import AVFoundation

class NoteViewController: UIViewController, CLLocationManagerDelegate {
    let locationManager = CLLocationManager()

    @IBOutlet weak var entireScrollView: UIScrollView!
    @IBOutlet weak var noteTitle: UITextField!
    @IBOutlet weak var noteDescription: UITextView!
    @IBOutlet weak var selectImageBtn: UIButton!
    @IBOutlet weak var imageScrollView: UIScrollView!
    @IBOutlet weak var audioContainerScrollView: UIScrollView!
    @IBOutlet weak var titleAndDescriptionContainerView: UIView!
    @IBOutlet weak var audioRecorderControlUIView: UIView!
    
    var noteID = ""
    var locationString = ""
    var noteData: Note? = nil
    var attachmentData: Attachments? = nil
    var noteIndex: Int? = nil
    let imageWidth: CGFloat = 398
    var xPosition: CGFloat = 0
    var audioScrollXPosition: CGFloat = 0
    var scrollViewContentWidth: CGFloat = 0
    var audioScrollViewContentWidth: CGFloat = 0
    var audioContainersScrollViewContentWidth: CGFloat = 0
    var isPlaybackRunning = false
    var audioRecorder = AVAudioRecorder()
    var audioPlayer = AVAudioPlayer()
    var currentAudioSlider = UISlider()
    var currentPlayPauseBtn = UIButton()
    var audioCount = 0
    var recordingsURLsToSave = [String]()
    
    var currentAudioPlayerView = AudioPlayerView()
    
    var addedImages = [UIImage]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        setupView()
    }
    
    func setupView(){
        noteDescription.delegate = self
        if(noteData != nil){
            setupEditViewItems()
        }
        else{
            setupNewViewItems()
        }
        setupAudioRecorderUI()
    }
    func setupEditViewItems(){
        
        //noteDescription.isScrollEnabled = false
        noteID = noteData!.noteID!
        noteTitle.text = noteData?.noteTitle
        noteDescription.text = noteData?.noteDescription
        for attachment in noteData!.attachmentsArray {
            handleImage(image: UIImage(data: attachment.attachmentBinary!)!, imageTag: TagConstants.savedImage)
        }
        
//        noteDescription.translatesAutoresizingMaskIntoConstraints = false
//        [
//            noteDescription.topAnchor.constraint(equalTo: noteTitle.bottomAnchor),
//            noteDescription.leadingAnchor.constraint(equalTo: titleAndDescriptionContainerView.leadingAnchor),
//            noteDescription.trailingAnchor.constraint(equalTo: titleAndDescriptionContainerView.trailingAnchor),
//            noteDescription.heightAnchor.constraint(equalToConstant: 50)
//            ].forEach{ $0.isActive = true }
        //textViewDidChange(noteDescription)
    }
    func setupNewViewItems(){
        setupLocationManager()
        noteID = UUID().uuidString
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
                managedObject.setValue(Date(), forKey: "updatedAt")


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
            note.noteID = noteID
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
        let chooseAction = UIAlertAction(title: "Choose a Photo", style: .default) { (action) in
            self.showImagePickerController(sourceType: .photoLibrary)
        }
        let saveAction = UIAlertAction(title: "Take a New Photo", style: .default) { (action) in
            self.showImagePickerController(sourceType: .camera)
        }
            
        // 3
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
            
        // 4
        alert.addAction(chooseAction)
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

extension NoteViewController: UITextViewDelegate{
//    func textViewDidChange(_ textView: UITextView) {
//        let size = CGSize(width: titleAndDescriptionContainerView.frame.width, height: .infinity)
//        let estimatedSize = noteDescription.sizeThatFits(size)
//        noteDescription.constraints.forEach{
//            (constraint) in if constraint.firstAttribute == .height{
//                constraint.constant = estimatedSize.height
//            }
//        }
//        titleAndDescriptionContainerView.constraints.forEach{
//            (constraint) in if constraint.firstAttribute == .height{
//                constraint.constant = estimatedSize.height + noteTitle.frame.height
//            }
//        }
//        entireScrollView.contentSize = CGSize(width: entireScrollView.frame.width, height: (imageScrollView.frame.height + titleAndDescriptionContainerView.frame.height + audioContainerView.frame.height))
//    }
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
}

extension NoteViewController: AVAudioPlayerDelegate, AVAudioRecorderDelegate {

    func setupAudioRecorderUI(){
        audioRecorderControlUIView.addSubview(getRecordAudioBtn())
        setupRecorder()
    }
    @IBAction func startRecordAudioBtnClicked(_ sender: UIButton){
//        for subview in self.audioRecorderControlUIView.subviews {
//               subview.removeFromSuperview()
//        }
        
        let recordingAudioAnimation = AnimationView()
        recordingAudioAnimation.frame = sender.superview!.bounds
        recordingAudioAnimation.animation = Animation.named("audioRecording")
        recordingAudioAnimation.loopMode = .loop
        recordingAudioAnimation.backgroundColor = .white
        recordingAudioAnimation.contentMode = .scaleAspectFill
        recordingAudioAnimation.play()
        let gesture:UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(stopRecordAudioBtnClicked(_:)))
        recordingAudioAnimation.addGestureRecognizer(gesture)
        sender.superview!.addSubview(recordingAudioAnimation)
        sender.removeFromSuperview()
        //start recording
        audioRecorder.record()
    }
    
    @IBAction func stopRecordAudioBtnClicked(_ sender: UITapGestureRecognizer){
        audioRecorder.stop()
        print("------\(sender)-------")
//        for subview in (sender.view as! UIView).superView! {
//               subview.removeFromSuperview()
//        }
        //sender.superview!.addSubview(getRecordAudioBtn())
        sender.view?.removeFromSuperview()
    }
    
    func getRecordAudioBtn() -> UIButton{
    let recordAudioBtn: UIButton = UIButton()
    recordAudioBtn.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
    recordAudioBtn.setImage(UIImage(named: "audioWaveStable"), for: .normal)
    recordAudioBtn.addTarget(self, action: #selector(startRecordAudioBtnClicked), for: .touchUpInside)
    return recordAudioBtn
    }
    
    func setupRecorder(){
        let recordSettings = [AVFormatIDKey: kAudioFormatAppleLossless,
                              AVEncoderAudioQualityKey: AVAudioQuality.max.rawValue,
                              AVEncoderBitRateKey: 128000,
                              AVNumberOfChannelsKey: 1 ] as [String : Any]
        do{
            audioRecorder = try AVAudioRecorder(url: getFIleURL(), settings: recordSettings)
            audioRecorder.delegate = self
            audioRecorder.prepareToRecord()
        }
        catch{
            
        }
        
    }
    
    func getCacheDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func getFIleURL() -> URL {
        audioCount += 1
        let audioName = "\(noteID)_\(Date().getFormattedDate(format: "MMM_d_yyyy_h:mm a"))"
        let path = getCacheDirectory().appendingPathComponent("\(audioName).m4a")
        //recordingsURLsToSave.append(String(describing: path))
        return path
    }
    
    
    func addRecorderdAudioPlayerUI(){
        //audioRecorderControlUIView.removeFromSuperview()
        
        let audioPlayerView = AudioPlayerView.loadViewFromNib()
        audioPlayerView.frame = CGRect(x: audioScrollXPosition, y: 0, width: 398, height: 50)
        audioPlayerView.audioURL.text = recordingsURLsToSave.last
        audioPlayerView.audioSlider.minimumValue = Float(0.0)
        audioPlayerView.audioSlider.maximumValue = Float(10)
        audioPlayerView.addTarget(forItem: "playAudio", target: self, action: #selector(self.playPauseAudioBtnCLicked), forControlEvents: .touchUpInside)
        audioPlayerView.addTarget(forItem: "deleteAudio", target: self, action: #selector(self.deleteAudioBtnCLicked), forControlEvents: .touchUpInside)
        audioPlayerView.addTarget(forItem: "audioSlider", target: self, action: #selector(self.changeAudioTime), forControlEvents: .valueChanged)
    
        audioScrollXPosition = audioScrollXPosition + audioPlayerView.frame.width + 10
        let frame1 = CGRect(x: audioScrollXPosition, y: 0, width: 50, height: audioContainerScrollView.frame.height )
        //audioRecorderControlUIView.frame = frame1
        
        audioContainerScrollView.addSubview(audioPlayerView)
        let newRecorderView = UIView(frame: frame1)
            newRecorderView.addSubview(getRecordAudioBtn())
        audioContainerScrollView.addSubview(newRecorderView)
        
        audioScrollViewContentWidth = audioPlayerView.frame.width + newRecorderView.frame.width + audioScrollViewContentWidth + 15
        audioContainerScrollView.contentSize = CGSize(width: audioScrollViewContentWidth, height: 50)
        audioScrollViewContentWidth -= newRecorderView.frame.width
    }
    
    @objc func changeAudioTime(_ sender: AnyObject){
        audioPlayer.stop()
        audioPlayer.currentTime = TimeInterval(getSliderFromAudioCOntrollerView(sender: sender).value)
        audioPlayer.prepareToPlay()
        audioPlayer.play()
    }
    @objc func playPauseAudioBtnCLicked(_ sender: UIButton){
        if sender.tag == 0{
            sender.setImage(UIImage(systemName: "pause.fill"), for: .normal)
            sender.tag = 1
            if isPlaybackRunning{
                audioPlayer.play()
            }
            else{
//                currentPlayPauseBtn.setImage(UIImage(systemName: "play.fill"), for: .normal)
                
                do{
                    isPlaybackRunning = true
                    currentPlayPauseBtn = getPlayPauseBtnFromAudioCOntrollerView(sender: sender)
                    audioPlayer = try AVAudioPlayer(contentsOf: URL(string: getLabelFromAudioCOntrollerView(sender: sender).text!)!)
                    audioPlayer.delegate = self
                    currentAudioSlider = getSliderFromAudioCOntrollerView(sender: sender)
                    currentAudioSlider.maximumValue = Float(audioPlayer.duration)
                    var timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(updateSLider), userInfo: nil, repeats: true)
                    audioPlayer.play()
                }
                catch{
                    
                }
            }
        }
        else{
            sender.setImage(UIImage(systemName: "play.fill"), for: .normal)
            sender.tag = 0
            audioPlayer.pause()
        }
    }
    
    @objc func deleteAudioBtnCLicked(_ sender: UIButton){
        print("delete")
    }

    func getSliderFromAudioCOntrollerView(sender: AnyObject) -> UISlider{
        return sender.superview?.subviews.first(where: {$0 is UISlider}) as! UISlider
    }
    
    func getPlayPauseBtnFromAudioCOntrollerView(sender: AnyObject) -> UIButton{
        return sender.superview?.subviews.first(where: {
            (($0 as! UIButton).tag == 0
            ||
                ($0 as! UIButton).tag == 1)
        }) as! UIButton
    }
    
    func getLabelFromAudioCOntrollerView(sender: AnyObject) -> UILabel{
        return sender.superview?.subviews.first(where: {$0 is UILabel}) as! UILabel
    }
    
    @objc func updateSLider(){
        currentAudioSlider.value = Float(audioPlayer.currentTime)
    }
    
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        print(recorder.url)
        recordingsURLsToSave.append(String(describing: recorder.url))
        addRecorderdAudioPlayerUI()
        
    }
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool){
        isPlaybackRunning = false
        currentPlayPauseBtn.setImage(UIImage(systemName: "play.fill"), for: .normal)
        currentPlayPauseBtn.tag = 0
    }
}
