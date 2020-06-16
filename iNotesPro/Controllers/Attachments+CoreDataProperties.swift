//
//  Attachments+CoreDataProperties.swift
//  iNotesPro
//
//  Created by Nirmal Sumanth on 16/06/20.
//  Copyright © 2020 Nirmal Sumanth. All rights reserved.
//
//

import Foundation
import CoreData


extension Attachments {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Attachments> {
        return NSFetchRequest<Attachments>(entityName: "Attachments")
    }

    @NSManaged public var attachmentBinary: Data?
    @NSManaged public var attachmentID: String?
    @NSManaged public var attachmentType: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var noteID: String?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var note: Note?

}
