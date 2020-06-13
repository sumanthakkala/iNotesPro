//
//  Note+CoreDataProperties.swift
//  iNotesPro
//
//  Created by Nirmal Sumanth on 12/06/20.
//  Copyright © 2020 Nirmal Sumanth. All rights reserved.
//
//

import Foundation
import CoreData


extension Note {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Note> {
        return NSFetchRequest<Note>(entityName: "Note")
    }

    @NSManaged public var noteID: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var noteTitle: String?
    @NSManaged public var noteDescription: String?
    @NSManaged public var location: String?

}
