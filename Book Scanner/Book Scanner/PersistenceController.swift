//
//  PersistenceController.swift
//  Book Scanner
//
//  Core Data persistence for saved books with iCloud sync for automatic restore on new devices.
//

import CoreData
import CloudKit

struct PersistenceController {
    static let shared = PersistenceController()
    static let preview = PersistenceController(inMemory: true)

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        let model = Self.model

        if inMemory {
            let container = NSPersistentContainer(name: "BookScanner", managedObjectModel: model)
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
            self.container = container
        } else {
            let cloudContainer = NSPersistentCloudKitContainer(name: "BookScanner", managedObjectModel: model)
            guard let description = cloudContainer.persistentStoreDescriptions.first else {
                self.container = cloudContainer
                cloudContainer.loadPersistentStores { _, _ in }
                return
            }
            description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
                containerIdentifier: "iCloud.com.israman.somenews.Book-Scanner"
            )
            description.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
            description.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
            self.container = cloudContainer
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

        bookEntity.properties = [
            idAttr, titleAttr, authorsAttr, isbnAttr,
            thumbnailURLStringAttr, publisherAttr, publishedDateAttr, bookDescriptionAttr, subjectsAttr,
            notesAttr, isFavoriteAttr
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
