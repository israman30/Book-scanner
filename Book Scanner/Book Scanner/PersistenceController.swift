//
//  PersistenceController.swift
//  Book Scanner
//
//  Core Data persistence for saved books.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()
    static let preview = PersistenceController(inMemory: true)

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        let model = Self.model
        container = NSPersistentContainer(name: "BookScanner", managedObjectModel: model)

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                #if DEBUG
                fatalError("Core Data failed to load: \(error), \(error.userInfo)")
                #else
                print("Core Data failed to load: \(error), \(error.userInfo)")
                #endif
            }
        }
    }

    private static let model: NSManagedObjectModel = {
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

        bookEntity.properties = [
            idAttr, titleAttr, authorsAttr, isbnAttr,
            thumbnailURLStringAttr, publisherAttr, publishedDateAttr, bookDescriptionAttr
        ]

        model.entities = [bookEntity]
        return model
    }()

    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    func save() {
        let context = viewContext
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            let nsError = error as NSError
            print("Core Data save error: \(nsError), \(nsError.userInfo)")
        }
    }
}
