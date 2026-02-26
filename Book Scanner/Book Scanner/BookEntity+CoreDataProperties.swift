//
//  BookEntity+CoreDataProperties.swift
//  Book Scanner
//
//  Core Data properties for BookEntity.
//

import CoreData
import Foundation

extension BookEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<BookEntity> {
        NSFetchRequest<BookEntity>(entityName: "BookEntity")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var authors: String?
    @NSManaged public var isbn: String?
    @NSManaged public var thumbnailURLString: String?
    @NSManaged public var publisher: String?
    @NSManaged public var publishedDate: String?
    @NSManaged public var bookDescription: String?
    @NSManaged public var subjects: String?
}

// MARK: - Conversion

extension BookEntity {
    /// Creates a BookEntity in the given context from a SavedBook (e.g. from API lookup).
    static func create(
        from savedBook: SavedBook,
        in context: NSManagedObjectContext
    ) -> BookEntity {
        let entity = BookEntity(context: context)
        entity.id = savedBook.id
        entity.title = savedBook.title
        entity.authors = savedBook.authors
        entity.isbn = savedBook.isbn
        entity.thumbnailURLString = savedBook.thumbnailURL?.absoluteString
        entity.publisher = savedBook.publisher
        entity.publishedDate = savedBook.publishedDate
        entity.bookDescription = savedBook.description
        entity.subjects = savedBook.subjects
        return entity
    }

    /// Converts this managed object to a value-type SavedBook for display/API.
    var toSavedBook: SavedBook {
        SavedBook(
            id: id ?? UUID(),
            title: title ?? "",
            authors: authors ?? "",
            isbn: isbn,
            thumbnailURL: thumbnailURLString.flatMap { URL(string: $0) },
            publisher: publisher,
            publishedDate: publishedDate,
            description: bookDescription,
            subjects: subjects
        )
    }
}
