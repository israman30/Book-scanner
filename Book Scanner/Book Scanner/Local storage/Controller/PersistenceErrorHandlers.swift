//
//  PersistencErrorHandlers.swift
//  Book Scanner
//
//  Created by Israel Manzo on 3/8/26.
//

import CoreData
import CloudKit

// MARK: - Persistence Error Handler

/// Converts Core Data NSErrors into human-readable messages for debugging and user feedback.
enum PersistenceErrorHandler {

    /// A structured representation of a persistence error with user-facing and debug info.
    struct ErrorMessage {
        /// Short, user-friendly message suitable for UI display.
        let userFacing: String
        /// Detailed message for debugging and logs.
        let debug: String
        /// Suggested recovery action, if applicable.
        let suggestion: String?
    }

    /// Parses a Core Data error and returns a structured ErrorMessage.
    static func parse(_ error: Error) -> ErrorMessage {
        let nsError = error as NSError

        switch (nsError.domain, nsError.code) {
        // MARK: - Core Data Store Load Errors
        case (NSCocoaErrorDomain, NSMigrationMissingSourceModelError):
            return ErrorMessage(
                userFacing: "Database migration failed: source model not found.",
                debug: "\(nsError.localizedDescription) | domain: \(nsError.domain) code: \(nsError.code)",
                suggestion: "Ensure the data model version history is intact. Consider resetting the store if this is a development build."
            )
        case (NSCocoaErrorDomain, NSMigrationMissingMappingModelError):
            return ErrorMessage(
                userFacing: "Database migration failed: mapping model not found.",
                debug: "\(nsError.localizedDescription) | userInfo: \(formatUserInfo(nsError.userInfo))",
                suggestion: "Add a mapping model for the schema change, or enable lightweight migration."
            )
        case (NSCocoaErrorDomain, NSMigrationManagerDestinationStoreError):
            return ErrorMessage(
                userFacing: "Database migration failed at destination store.",
                debug: "\(nsError.localizedDescription) | userInfo: \(formatUserInfo(nsError.userInfo))",
                suggestion: "Check disk space and store permissions."
            )
        case (NSCocoaErrorDomain, NSPersistentStoreInvalidTypeError):
            return ErrorMessage(
                userFacing: "Invalid store type or configuration.",
                debug: "\(nsError.localizedDescription) | userInfo: \(formatUserInfo(nsError.userInfo))",
                suggestion: "Verify persistent store description and store type."
            )
        case (NSCocoaErrorDomain, NSPersistentStoreIncompatibleVersionHashError):
            return ErrorMessage(
                userFacing: "Database schema has changed and migration is required.",
                debug: "\(nsError.localizedDescription) | userInfo: \(formatUserInfo(nsError.userInfo))",
                suggestion: "Ensure NSMigratePersistentStoresAutomaticallyOption and NSInferMappingModelAutomaticallyOption are enabled."
            )
        case (NSCocoaErrorDomain, NSPersistentStoreOperationError):
            return ErrorMessage(
                userFacing: "Database operation failed.",
                debug: "\(nsError.localizedDescription) | userInfo: \(formatUserInfo(nsError.userInfo))",
                suggestion: "Check disk space, permissions, and that the store file is not corrupted."
            )
        case (NSCocoaErrorDomain, NSPersistentStoreOpenError):
            return ErrorMessage(
                userFacing: "Could not open the database.",
                debug: "\(nsError.localizedDescription) | userInfo: \(formatUserInfo(nsError.userInfo))",
                suggestion: "The store may be locked by another process or corrupted. Try restarting the app."
            )
        case (NSCocoaErrorDomain, NSPersistentStoreSaveError):
            return ErrorMessage(
                userFacing: "Could not save to the database.",
                debug: "\(nsError.localizedDescription) | userInfo: \(formatUserInfo(nsError.userInfo))",
                suggestion: "Check disk space and try again."
            )

        // MARK: - Validation Errors (Save)
        case (NSCocoaErrorDomain, NSValidationStringTooLongError),
             (NSCocoaErrorDomain, NSValidationStringTooShortError):
            let key = nsError.userInfo[NSValidationKeyErrorKey] as? String ?? "field"
            return ErrorMessage(
                userFacing: "Invalid data: '\(key)' has an invalid length.",
                debug: "Validation error for key '\(key)' | userInfo: \(formatUserInfo(nsError.userInfo))",
                suggestion: "Check that text fields are within allowed limits."
            )
        case (NSCocoaErrorDomain, NSValidationNumberTooLargeError),
             (NSCocoaErrorDomain, NSValidationNumberTooSmallError):
            let key = nsError.userInfo[NSValidationKeyErrorKey] as? String ?? "field"
            return ErrorMessage(
                userFacing: "Invalid data: '\(key)' is out of range.",
                debug: "Validation error for key '\(key)' | userInfo: \(formatUserInfo(nsError.userInfo))",
                suggestion: nil
            )
        case (NSCocoaErrorDomain, NSValidationRelationshipLacksMinimumCountError),
             (NSCocoaErrorDomain, NSValidationRelationshipExceedsMaximumCountError):
            let key = nsError.userInfo[NSValidationKeyErrorKey] as? String ?? "relationship"
            return ErrorMessage(
                userFacing: "Invalid relationship: '\(key)' has wrong number of related items.",
                debug: "Relationship validation for '\(key)' | userInfo: \(formatUserInfo(nsError.userInfo))",
                suggestion: nil
            )
        case (NSCocoaErrorDomain, NSValidationMissingMandatoryPropertyError):
            let key = nsError.userInfo[NSValidationKeyErrorKey] as? String ?? "property"
            return ErrorMessage(
                userFacing: "Required field '\(key)' is missing.",
                debug: "Missing mandatory property '\(key)' | userInfo: \(formatUserInfo(nsError.userInfo))",
                suggestion: "Ensure all required fields are set before saving."
            )
        case (NSCocoaErrorDomain, NSManagedObjectConstraintMergeError):
            return ErrorMessage(
                userFacing: "Duplicate or conflicting data detected.",
                debug: "Constraint merge conflict | userInfo: \(formatUserInfo(nsError.userInfo))",
                suggestion: "A record with this identifier may already exist. Try refreshing or removing duplicates."
            )

        // MARK: - CloudKit Errors (when using NSPersistentCloudKitContainer)
        case (CKError.errorDomain, CKError.networkUnavailable.rawValue),
             (CKError.errorDomain, CKError.networkFailure.rawValue):
            return ErrorMessage(
                userFacing: "iCloud sync unavailable: no network connection.",
                debug: "CloudKit network error | code: \(nsError.code)",
                suggestion: "Connect to the internet and try again. Data is saved locally and will sync when online."
            )
        case (CKError.errorDomain, CKError.notAuthenticated.rawValue):
            return ErrorMessage(
                userFacing: "iCloud sync requires signing in to your Apple ID.",
                debug: "CloudKit not authenticated | code: \(nsError.code)",
                suggestion: "Sign in to iCloud in Settings to enable sync across devices."
            )
        case (CKError.errorDomain, CKError.quotaExceeded.rawValue):
            return ErrorMessage(
                userFacing: "iCloud storage is full.",
                debug: "CloudKit quota exceeded | code: \(nsError.code)",
                suggestion: "Free up iCloud storage in Settings to continue syncing."
            )

        // MARK: - Fallback
        default:
            return ErrorMessage(
                userFacing: nsError.localizedDescription.isEmpty
                    ? "An unexpected error occurred (code \(nsError.code))."
                    : nsError.localizedDescription,
                debug: "domain: \(nsError.domain) | code: \(nsError.code) | \(nsError.localizedDescription) | userInfo: \(formatUserInfo(nsError.userInfo))",
                suggestion: nil
            )
        }
    }

    /// Formats userInfo into a readable string for logging.
    private static func formatUserInfo(_ userInfo: [String: Any]) -> String {
        userInfo
            .map { "\($0.key): \($0.value)" }
            .joined(separator: ", ")
    }

    /// Returns a single-line message suitable for logging.
    static func logMessage(for error: Error) -> String {
        let msg = parse(error)
        return "[Persistence] \(msg.userFacing) | Debug: \(msg.debug)" + (msg.suggestion.map { " | Suggestion: \($0)" } ?? "")
    }

    /// Returns the user-facing message for UI display.
    static func userMessage(for error: Error) -> String {
        parse(error).userFacing
    }
}
