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

class NoteViewController: UIViewController, CLLocationManagerDelegate, CALayerDelegate, UIScrollViewDelegate {
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
    var recordingsDataToSave = [Data]()
    var existingRecordings = [Attachments]()
    var totalRecordingsData = [Data]()
    var audiosIndexForSlider = 0
    var currentAudioPlayerView = AudioPlayerView()
    private var gradient: CAGradientLayer!
    var addedImages = [UIImage]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        setupView()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.isAtTop {
            self.applyGradient_To(state: "Bot")
        } else if scrollView.isAtBottom {
            self.applyGradient_To(state: "Top")
        } else {
            self.applyGradient_To(state: "Both")
        }
    }
    
    func applyGradient_To (state: String) {
        let gradient = CAGradientLayer()
        gradient.frame = self.noteDescription!.bounds

        switch state {
        case "Top":
            gradient.colors = [UIColor.clear.cgColor,UIColor.white.cgColor]
            gradient.locations = [0.0,0.2]
        case "Bot":
            gradient.colors = [UIColor.white.cgColor, UIColor.clear.cgColor]
            gradient.locations = [0.8,1.0]
        default:
            gradient.colors = [UIColor.clear.cgColor,UIColor.white.cgColor,UIColor.white.cgColor, UIColor.clear.cgColor]
            gradient.locations = [0, 0.2, 0.8, 1]
        }
        self.noteDescription!.layer.mask = nil
        self.noteDescription!.layer.mask = gradient
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
        
        noteID = noteData!.noteID!
        noteTitle.text = noteData?.noteTitle
        noteDescription.text = noteData?.noteDescription
        let existingImages = noteData!.attachmentsArray.filter{
            $0.attachmentType == AttachmentConstants.image
        }
        for attachment in existingImages {
            handleImage(image: UIImage(data: attachment.attachmentBinary!)!, imageTag: TagConstants.savedImage)
        }
        existingRecordings = noteData!.attachmentsArray.filter{
            $0.attachmentType == AttachmentConstants.audio
        }
        for recording in existingRecordings{
            totalRecordingsData.append(recording.attachmentBinary!)
        }
        addExistingAudiosUI(existingAudios: existingRecordings)
        gradient = CAGradientLayer()
        gradient.frame = noteDescription.bounds
        gradient.colors = [UIColor.clear.cgColor, UIColor.black.cgColor, UIColor.black.cgColor, UIColor.clear.cgColor]
        gradient.locations = [0, 0, 0.8, 1]
        noteDescription.layer.mask = gradient
    }
    func setupNewViewItems(){
        setupLocationManager()
        noteID = UUID().uuidString
        gradient = CAGradientLayer()
        gradient.frame = noteDescription.bounds
        gradient.colors = [UIColor.clear.cgColor, UIColor.black.cgColor, UIColor.black.cgColor, UIColor.clear.cgColor]
        gradient.locations = [0, 0, 0.8, 1]
        noteDescription.layer.mask = gradient
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
        fetchRequest.predicate = NSPredicate(format: "noteID = %@", noteData?.noteID as! CVarArg)

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
                if recordingsDataToSave.count > 0{
                    for audio in recordingsDataToSave {
                        let audioAttachment = Attachments(context: PersistanceService.context)
                        audioAttachment.attachmentID = UUID().uuidString
                        audioAttachment.noteID = noteData!.noteID
                        audioAttachment.attachmentBinary = audio
                        audioAttachment.createdAt = Date()
                        audioAttachment.updatedAt = Date()
                        audioAttachment.attachmentType = AttachmentConstants.audio
                        noteData!.addToAttachments(audioAttachment)
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
            
            if recordingsDataToSave.count > 0{
                for audio in recordingsDataToSave {
                    let audioAttachment = Attachments(context: PersistanceService.context)
                    audioAttachment.attachmentID = UUID().uuidString
                    audioAttachment.noteID = note.noteID
                    audioAttachment.attachmentBinary = audio
                    audioAttachment.createdAt = Date()
                    audioAttachment.updatedAt = Date()
                    audioAttachment.attachmentType = AttachmentConstants.audio
                    note.addToAttachments(audioAttachment)
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
        
        
        addBtn.setImage(boldSearch, for: .normal)
        addBtn.backgroundColor = UIColor.systemBackground
        addBtn.tintColor = noteTitle.textColor
        
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
        audioContainerScrollView.viewWithTag(TagConstants.recordAudioView)?.removeFromSuperview()
        print(audioContainerScrollView.subviews.count)
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
        let audioName = "\(noteID)_\(Date().getFormattedDate(format: "MMM_d_yyyy_h:mm:ss Z a"))"
        let path = getCacheDirectory().appendingPathComponent("\(audioName).m4a")
        return path
    }
    
    
    func addRecorderdAudioPlayerUI(){
        let audioPlayerView = AudioPlayerView.loadViewFromNib()
        audioPlayerView.frame = CGRect(x: audioScrollXPosition, y: 0, width: 398, height: 50)
        audioPlayerView.audioIndexIntTotalAudios.text = String(audiosIndexForSlider)
        audiosIndexForSlider += 1
        audioPlayerView.audioSlider.minimumValue = Float(0.0)
        audioPlayerView.audioSlider.maximumValue = Float(10)
        
        audioPlayerView.addTarget(forItem: "playAudio", target: self, action: #selector(self.playPauseAudioBtnCLicked), forControlEvents: .touchUpInside)
        audioPlayerView.addTarget(forItem: "deleteAudio", target: self, action: #selector(self.deleteAudioBtnCLicked), forControlEvents: .touchUpInside)
        audioPlayerView.addTarget(forItem: "audioSlider", target: self, action: #selector(self.changeAudioTime), forControlEvents: .valueChanged)
    
        audioScrollXPosition = audioScrollXPosition + audioPlayerView.frame.width + 10
        let frame1 = CGRect(x: audioScrollXPosition, y: 0, width: 50, height: audioContainerScrollView.frame.height )
        audioPlayerView.tag = TagConstants.recorderAudio
        audioContainerScrollView.addSubview(audioPlayerView)
        let newRecorderView = UIView(frame: frame1)
            newRecorderView.addSubview(getRecordAudioBtn())
        newRecorderView.tag = TagConstants.recordAudioView
        audioContainerScrollView.addSubview(newRecorderView)
        print(audioContainerScrollView.subviews.count)
        
        audioScrollViewContentWidth = audioPlayerView.frame.width + newRecorderView.frame.width + audioScrollViewContentWidth + 15
        audioContainerScrollView.contentSize = CGSize(width: audioScrollViewContentWidth, height: 50)
        audioScrollViewContentWidth -= newRecorderView.frame.width
        setupRecorder()
    }
    
    func addExistingAudiosUI(existingAudios: [Attachments]){
        if existingAudios.count != 0 {
            audioRecorderControlUIView.removeFromSuperview()
            for _ in existingAudios{
                let audioPlayerView = AudioPlayerView.loadViewFromNib()
                    audioPlayerView.frame = CGRect(x: audioScrollXPosition, y: 0, width: 398, height: 50)
                    audioPlayerView.audioSlider.minimumValue = Float(0.0)
                    audioPlayerView.audioSlider.maximumValue = Float(10)
                audioPlayerView.audioIndexIntTotalAudios.text = String(audiosIndexForSlider)
                audiosIndexForSlider += 1
                    audioPlayerView.addTarget(forItem: "playAudio", target: self, action: #selector(self.playPauseAudioBtnCLicked), forControlEvents: .touchUpInside)
                    audioPlayerView.addTarget(forItem: "deleteAudio", target: self, action: #selector(self.deleteAudioBtnCLicked), forControlEvents: .touchUpInside)
                    audioPlayerView.addTarget(forItem: "audioSlider", target: self, action: #selector(self.changeAudioTime), forControlEvents: .valueChanged)
                
                    audioScrollXPosition = audioScrollXPosition + audioPlayerView.frame.width + 10
                    audioPlayerView.tag = TagConstants.savedAudio
                    audioContainerScrollView.addSubview(audioPlayerView)
                audioScrollViewContentWidth += 398
                
            }
            let frame1 = CGRect(x: audioScrollXPosition, y: 0, width: 50, height: audioContainerScrollView.frame.height )
            let newRecorderView = UIView(frame: frame1)
                newRecorderView.addSubview(getRecordAudioBtn())
            newRecorderView.tag = TagConstants.recordAudioView
            audioContainerScrollView.addSubview(newRecorderView)
            
            audioScrollViewContentWidth = newRecorderView.frame.width + audioScrollViewContentWidth + 20
            audioContainerScrollView.contentSize = CGSize(width: audioScrollViewContentWidth, height: 50)
            audioScrollViewContentWidth -= newRecorderView.frame.width
            setupRecorder()
        }
        
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
            let senderLable = getLabelFromAudioCOntrollerView(sender: sender)
            if isPlaybackRunning && (senderLable.text != audioPlayer.url?.absoluteString){
                isPlaybackRunning = false
                audioPlayer.stop()
                currentPlayPauseBtn.setImage(UIImage(systemName: "play.fill"), for: .normal)
                currentPlayPauseBtn.tag = 0
                currentAudioSlider.value = Float(0)
                setupPlayerAndPlayAudio(sender: sender)
            }
            else{
                if isPlaybackRunning{
                                audioPlayer.play()
                            }
                            else{
                    setupPlayerAndPlayAudio(sender: sender)
                                
                            }
            }
            
            sender.tag = 1
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
    
    func setupPlayerAndPlayAudio(sender: AnyObject){
        do{
            currentPlayPauseBtn = getPlayPauseBtnFromAudioCOntrollerView(sender: sender)
            let index = Int(getLabelFromAudioCOntrollerView(sender: sender).text!)
            if (sender.superview as! AudioPlayerView).tag == TagConstants.recorderAudio{
                
                audioPlayer = try AVAudioPlayer(data: totalRecordingsData[index!])
            }
            else{
                audioPlayer = try AVAudioPlayer(data: totalRecordingsData[index!])
            }
            audioPlayer.delegate = self
            currentAudioSlider = getSliderFromAudioCOntrollerView(sender: sender)
            currentAudioSlider.maximumValue = Float(audioPlayer.duration)
            _ = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(updateSLider), userInfo: nil, repeats: true)
            audioPlayer.play()
            isPlaybackRunning = true
        }
        catch{
            print(error.localizedDescription)
        }

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
        if FileManager.default.fileExists(atPath: recorder.url.path){
            if let cert = NSData(contentsOfFile: recorder.url.path) {
                recordingsDataToSave.append(cert as Data)
                totalRecordingsData.append(cert as Data)
            }
        }
        addRecorderdAudioPlayerUI()
        
    }
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool){
        isPlaybackRunning = false
        currentPlayPauseBtn.setImage(UIImage(systemName: "play.fill"), for: .normal)
        currentPlayPauseBtn.tag = 0
    }
}

extension UIScrollView {

    var isAtTop: Bool {
        return contentOffset.y <= verticalOffsetForTop
    }

    var isAtBottom: Bool {
        return contentOffset.y >= verticalOffsetForBottom
    }

    var verticalOffsetForTop: CGFloat {
        let topInset = contentInset.top
        return -topInset
    }

    var verticalOffsetForBottom: CGFloat {
        let scrollViewHeight = bounds.height
        let scrollContentSizeHeight = contentSize.height
        let bottomInset = contentInset.bottom
        let scrollViewBottomOffset = scrollContentSizeHeight + bottomInset - scrollViewHeight
        return scrollViewBottomOffset
    }

}
