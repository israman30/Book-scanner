//
//  PersistenceController.swift
//  Book Scanner
//
//  Core Data persistence for saved books.
//  Uses CloudKit-backed stores in production to keep the user's library synced across devices,
//  and an in-memory store for previews/tests.
//

import CoreData
import CloudKit


// MARK: - PersistenceController

struct PersistenceController {
    /// App-wide singleton used by the live app.
    static let shared = PersistenceController()
    /// In-memory store used by SwiftUI previews and unit tests.
    static let preview = PersistenceController(inMemory: true)

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        // This project builds the Core Data model programmatically to keep the data model
        // colocated with the entity type and avoid requiring a `.xcdatamodeld` file.
        let model = Self.model

        if inMemory {
            // In-memory store avoids writing to disk and keeps preview/test runs isolated.
            let container = NSPersistentContainer(name: "BookScanner", managedObjectModel: model)
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
            self.container = container
        } else {
            // CloudKit store enables automatic cross-device sync + restore when the user
            // signs into the same iCloud account.
            let cloudContainer = NSPersistentCloudKitContainer(name: "BookScanner", managedObjectModel: model)
            guard let description = cloudContainer.persistentStoreDescriptions.first else {
                self.container = cloudContainer
                cloudContainer.loadPersistentStores { _, _ in }
                return
            }
            description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
                containerIdentifier: "iCloud.com.israman.somenews.Book-Scanner"
            )
            // Lightweight migration keeps the app resilient when the model evolves.
            description.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
            description.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
            self.container = cloudContainer
        }

        // Loads the persistent stores once at startup; failures are not recoverable in DEBUG
        // (fail fast), but should not crash release builds where we can at least log details.
        self.container.loadPersistentStores { _, error in
            if let error = error {
                let msg = PersistenceErrorHandler.parse(error)
                #if DEBUG
                fatalError("Core Data failed to load: \(msg.debug)")
                #else
                print(PersistenceErrorHandler.logMessage(for: error))
                #endif
            }
        }
    }

    private static let model: NSManagedObjectModel = {
        // Defines a minimal schema for the user's saved library entries.
        // If you add a field to `SavedBook` / `BookEntity`, ensure it's reflected here.
        let model = NSManagedObjectModel()

        let bookEntity = NSEntityDescription()
        bookEntity.name = "BookEntity"
        bookEntity.managedObjectClassName = "BookEntity"

        let idAttr = NSAttributeDescription()
        idAttr.name = "id"
        idAttr.attributeType = .UUIDAttributeType

        let titleAttr = NSAttributeDescription()
        titleAttr.name = "title"
        titleAttr.attributeType = .stringAttributeType

        let authorsAttr = NSAttributeDescription()
        authorsAttr.name = "authors"
        authorsAttr.attributeType = .stringAttributeType

        let isbnAttr = NSAttributeDescription()
        isbnAttr.name = "isbn"
        isbnAttr.attributeType = .stringAttributeType
        isbnAttr.isOptional = true

        let thumbnailURLStringAttr = NSAttributeDescription()
        thumbnailURLStringAttr.name = "thumbnailURLString"
        thumbnailURLStringAttr.attributeType = .stringAttributeType
        thumbnailURLStringAttr.isOptional = true

        let publisherAttr = NSAttributeDescription()
        publisherAttr.name = "publisher"
        publisherAttr.attributeType = .stringAttributeType
        publisherAttr.isOptional = true

        let publishedDateAttr = NSAttributeDescription()
        publishedDateAttr.name = "publishedDate"
        publishedDateAttr.attributeType = .stringAttributeType
        publishedDateAttr.isOptional = true

        let bookDescriptionAttr = NSAttributeDescription()
        bookDescriptionAttr.name = "bookDescription"
        bookDescriptionAttr.attributeType = .stringAttributeType
        bookDescriptionAttr.isOptional = true

        let subjectsAttr = NSAttributeDescription()
        subjectsAttr.name = "subjects"
        subjectsAttr.attributeType = .stringAttributeType
        subjectsAttr.isOptional = true

        let notesAttr = NSAttributeDescription()
        notesAttr.name = "notes"
        notesAttr.attributeType = .stringAttributeType
        notesAttr.isOptional = true

        let isFavoriteAttr = NSAttributeDescription()
        isFavoriteAttr.name = "isFavorite"
        isFavoriteAttr.attributeType = .booleanAttributeType
        isFavoriteAttr.defaultValue = false

        let addedDateAttr = NSAttributeDescription()
        addedDateAttr.name = "addedDate"
        addedDateAttr.attributeType = .dateAttributeType
        addedDateAttr.isOptional = true

        bookEntity.properties = [
            idAttr, titleAttr, authorsAttr, isbnAttr,
            thumbnailURLStringAttr, publisherAttr, publishedDateAttr, bookDescriptionAttr, subjectsAttr,
            notesAttr, isFavoriteAttr, addedDateAttr
        ]

        model.entities = [bookEntity]
        return model
    }()

    var viewContext: NSManagedObjectContext {
        // The main-queue context used by SwiftUI views.
        container.viewContext
    }

    func save() {
        // Central save helper to keep error handling consistent across the app.
        let context = viewContext
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            print(PersistenceErrorHandler.logMessage(for: error))
        }
    }
}
