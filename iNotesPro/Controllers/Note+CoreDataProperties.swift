//
//  Note+CoreDataProperties.swift
//  iNotesPro
//
//  Created by Nirmal Sumanth on 16/06/20.
//  Copyright © 2020 Nirmal Sumanth. All rights reserved.
//
//

import Foundation
import CoreData


extension Note {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Note> {
        return NSFetchRequest<Note>(entityName: "Note")
    }

    @NSManaged public var createdAt: Date?
    @NSManaged public var isActive: Bool
    @NSManaged public var location: String?
    @NSManaged public var noteDescription: String?
    @NSManaged public var noteID: String?
    @NSManaged public var noteTitle: String?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var attachments: NSSet?

    public var attachmentsArray: [Attachments] {
        let set = attachments as? Set<Attachments> ?? []
        return set.sorted{
            $0.createdAt!.compare($1.createdAt!) == .orderedAscending
        }
    }
}

// MARK: Generated accessors for attachments
extension Note {

    @objc(addAttachmentsObject:)
    @NSManaged public func addToAttachments(_ value: Attachments)

    @objc(removeAttachmentsObject:)
    @NSManaged public func removeFromAttachments(_ value: Attachments)

    @objc(addAttachments:)
    @NSManaged public func addToAttachments(_ values: NSSet)

    @objc(removeAttachments:)
    @NSManaged public func removeFromAttachments(_ values: NSSet)

}
