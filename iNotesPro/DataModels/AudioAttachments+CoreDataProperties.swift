//
//  AudioAttachments+CoreDataProperties.swift
//  iNotesPro
//
//  Created by Nirmal Sumanth on 22/06/20.
//  Copyright © 2020 Nirmal Sumanth. All rights reserved.
//
//

import Foundation
import CoreData


extension AudioAttachments {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<AudioAttachments> {
        return NSFetchRequest<AudioAttachments>(entityName: "AudioAttachments")
    }

    @NSManaged public var attachmentID: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var attachmentType: String?
    @NSManaged public var noteID: String?
    @NSManaged public var attachmentURL: String?
    @NSManaged public var note: Note?

}
