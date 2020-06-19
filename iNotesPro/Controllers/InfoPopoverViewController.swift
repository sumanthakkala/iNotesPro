//
//  InfoPopoverViewController.swift
//  iNotesPro
//
//  Created by Nirmal Sumanth on 18/06/20.
//  Copyright © 2020 Nirmal Sumanth. All rights reserved.
//

import UIKit
import MapKit
import Lottie

class InfoPopoverViewController: UIViewController {

    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var noteCreateAnimationView: UIView!
    @IBOutlet weak var createdDateLabel: UILabel!
    @IBOutlet weak var noteEditAnimationView: UIView!
    @IBOutlet weak var updatedDateLabel: UILabel!
    @IBOutlet weak var treeAnimationView: UIView!
    @IBOutlet weak var celebrationAnimationView: UIView!
    var note: Note? = nil
    override func viewDidLoad() {
        super.viewDidLoad()
        map.delegate = self
        // Do any additional setup after loading the view.
        let coordinatesArray = note!.location!.components(separatedBy: " ")
        let lat = Double(coordinatesArray[0])
        let lon = Double(coordinatesArray[0])
        let coordinate = CLLocationCoordinate2D(latitude:lat!
                                , longitude:lon!)
        
        let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 10000, longitudinalMeters: 10000)
        map.setRegion(map.regionThatFits(region), animated: true)

        let myPin: MKPointAnnotation = MKPointAnnotation()
        myPin.coordinate = coordinate
        //tappedLocations.append(touchMapCoordinate)
        myPin.title = ""
        map.addAnnotation(myPin)
        setupAnimations()
        createdDateLabel.text = "Created on \(String(describing: note!.createdAt!.getFormattedDate(format: "MMM d, yyyy | h:mm a")))"
        updatedDateLabel.text = "Edited on \(String(describing: note!.updatedAt!.getFormattedDate(format: "MMM d, yyyy | h:mm a")))"

    }
    func setupAnimations()
    {
        let createAnimationView = AnimationView()
        createAnimationView.frame = noteCreateAnimationView.bounds
        createAnimationView.animation = Animation.named("fileCreateFinal")
        createAnimationView.loopMode = .loop
        createAnimationView.backgroundColor = .white
        createAnimationView.contentMode = .scaleAspectFill
        createAnimationView.play()
        noteCreateAnimationView.addSubview(createAnimationView)
        
        
        
        let updateAnimationView = AnimationView()
        updateAnimationView.frame = noteEditAnimationView.bounds
        updateAnimationView.animation = Animation.named("fileEdit")
        updateAnimationView.loopMode = .loop
        updateAnimationView.backgroundColor = .white
        updateAnimationView.contentMode = .scaleAspectFill
        updateAnimationView.play()
        noteEditAnimationView.addSubview(updateAnimationView)
        
        let treeAnimation = AnimationView()
        treeAnimation.frame = treeAnimationView.bounds
        treeAnimation.animation = Animation.named("trees")
        treeAnimation.loopMode = .loop
        treeAnimation.backgroundColor = .white
        treeAnimation.contentMode = .scaleAspectFill
        treeAnimation.play()
        treeAnimationView.addSubview(treeAnimation)
        
        let celebrationAnimation = AnimationView()
        celebrationAnimation.frame = celebrationAnimationView.bounds
        celebrationAnimation.animation = Animation.named("celebration")
        celebrationAnimation.loopMode = .playOnce
        celebrationAnimation.backgroundColor = .white
        celebrationAnimation.contentMode = .scaleAspectFill
        celebrationAnimation.play()
        celebrationAnimationView.addSubview(celebrationAnimation)
    }
}

extension InfoPopoverViewController: MKMapViewDelegate {
    
//    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
//
//            if (annotation.isKind(of: MKUserLocation.self)) {
//                return nil
//            }
//        if annotation.isKind(of: MKPointAnnotation.self) {
//            let anView = MKAnnotationView()
//            //_ = annotation as! MKPointAnnotation
//            let height = 200
//            let width = 200
//            let animationView = AnimationView(frame: CGRect(x: 0, y: 0, width: width, height: height))
//
//            animationView.animation = Animation.named("greenBouncePin")
//            animationView.loopMode = .loop
//            animationView.backgroundColor = .white
//            animationView.contentMode = .scaleAspectFill
//            animationView.play()
//            anView.addSubview(animationView)
//
//            return anView
//        }
//    return nil
//    }
    
    //MARK: - render for overlay
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline {
            let rendrer = MKPolylineRenderer(overlay: overlay)
            rendrer.strokeColor = UIColor.blue
            rendrer.lineWidth = 3
            
            return rendrer
        }
        return MKOverlayRenderer()
    }
}
