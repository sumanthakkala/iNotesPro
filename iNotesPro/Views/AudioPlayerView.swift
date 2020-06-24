//
//  AudioPlayerView.swift
//  iNotesPro
//
//  Created by Nirmal Sumanth on 22/06/20.
//  Copyright © 2020 Nirmal Sumanth. All rights reserved.
//

import UIKit

class AudioPlayerView: UIView {
    @IBOutlet weak var playAudio: UIButton!
    @IBOutlet weak var deleteAudio: UIButton!
    @IBOutlet weak var audioSlider: UISlider!
    @IBOutlet weak var audioIndexIntTotalAudios: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        //self.isUserInteractionEnabled = false
        //commonInit()
    }
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    func commonInit(){
        let viewFromXIB = Bundle.main.loadNibNamed("AudioPlayerView", owner: self, options: nil)![0] as! UIView
        viewFromXIB.frame = self.bounds
        addSubview(viewFromXIB)
    }
    class func getInstance() -> AudioPlayerView {
      let viewFromXIB = Bundle.main.loadNibNamed("AudioPlayerView", owner: self, options: nil)![0] as! AudioPlayerView
      return  viewFromXIB
    }
    class func loadViewFromNib() -> AudioPlayerView {
        let nib = UINib(nibName: "AudioPlayerView", bundle: nil)
        return (nib.instantiate(withOwner: self, options: nil).first as? AudioPlayerView)!
    }
    func addTarget(forItem: String, target: AnyObject, action: Selector, forControlEvents: UIControl.Event) {
        if forItem == "playAudio"{
            playAudio.addTarget(target, action: action, for: forControlEvents)
        }
        if forItem == "audioSlider"{
            audioSlider.addTarget(target, action: action, for: forControlEvents)
        }
        if forItem == "deleteAudio"{
            deleteAudio.addTarget(target, action: action, for: forControlEvents)
        }
        
    }

}
