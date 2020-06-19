//
//  NotesTableViewCell.swift
//  iNotesPro
//
//  Created by Nirmal Sumanth on 12/06/20.
//  Copyright © 2020 Nirmal Sumanth. All rights reserved.
//

import UIKit

class NotesTableViewCell: UITableViewCell {

    @IBOutlet weak var noteCellTitle: UILabel!
    @IBOutlet weak var noteCellDescription: UILabel!
    @IBOutlet weak var noteCreatedDate: UILabel!
    @IBOutlet weak var infoButton: UIButton!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    var infoButtonAction: ((Any) -> Void)?

    @objc func infoButtonPressed(sender: Any) {
        self.infoButtonAction?(sender)
    }

}
