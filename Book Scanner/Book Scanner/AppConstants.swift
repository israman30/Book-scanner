import Foundation

enum SearchType: String, CaseIterable {
    case isbn = "ISBN"
    case author = "Author"
    case title = "Title"
    case subject = "Subject"
}

struct AppConstants {
    struct Strings {
        static let appName = "Book Scanner"
        
        // App Version
        static let appVersion = ""
        
        // @AppStorage
        static let storage = "hasCompletedOnboarding"
        
        // Onboarding
        static let scanBookBarcodes = "Scan Book Barcodes"
        static let browseSubjects = "Browse by Subject"
        static let saveAndOrganize = "Save & Organize"
        static let buildYourPersonalBookLibrary = "Build your personal book library by scanning barcodes, browsing by subject, and saving your favorites."
        static let tapScanNowToOpenTheCamera = "Tap \"Scan Now\" to open the camera. Align a book's barcode or QR code in the frame to look up book details instantly."
        static let useBrowseBooksToSearchByISBNAuthorTitleSubject = "Use \"Browse Books\" to search by ISBN, author, title, or subject. Discover new reads from the Open Library catalog."
        static let addBooksToYourLibraryAndAccessThemAnytimeEditDetailsSharelist = "Add books to your library and access them anytime. Edit details, share your list, or browse your collection by subject."
        static let getStarted = "Get Started"
        static let `continue` = "Continue"

        // App / home
        static let welcome = "Welcome to Book Scanner"
        static let scanNow = "Scan Now"
        static let browseBooks = "Browse Books"
        static let viewSavedBooks = "View Saved Books"
        static let loadingBooks = "Loading books..."
        static let version = "Version"
        static let noBooksYet = "No books yet"
        static let noBooksYetHint = "Scan and add books to see them here"
        static let noBooksYetDescription = "Scan and add books to see them here."

        // Scanner
        static let alignCodeInFrame = "Align the code in the frame"
        static let lookingUpBook = "Looking up book..."
        static let lookingUpBookDetails = "Looking up book details"
        static let noBookFound = "No book found"
        static let addToMyBooks = "Add to My Books"
        static let scannedCode = "Scanned code"
        static let codeCaptured = "Code captured. Looking up book details."
        static let bookFound = "Book found:"
        static let screenshotTitle = "Scanned:"
        static let cameraAccessNeeded = "Camera Access Needed"
        static let cameraAccessMessage = "Enable camera permissions in Settings to scan barcodes and QR codes."
        static let closeScanner = "Close scanner"
        static let closeScannerHint = "Returns to the previous screen"
        static let scannerViewLabel = "Live camera view for barcode scanning"
        static let scannerViewHint = "Align the code inside the green frame to scan"
        static let alignCodeHint = "Move your device until the barcode is centered"
        static let existingBook = "This book is already in your list."
        static func errorSearchingUpBook(_ error: String) -> String {
            "Could not save book: \(error)"
        }

        // Browse/search
        static let searchBy = "Search by"
        static let searchType = "Search type"
        static let publishedInOptional = "Published in (optional)"
        static let publishedInExample = "e.g. 1500-1600 or leave empty"
        static let search = "Search"
        static let browseBooksTitle = "Browse Books"
        static let done = "Done"
        static let ok = "OK"
        static let noResultsFound = "No results found"
        static let unknown = "Unknown"
        static let unknownTitle = "Unknown Title"
        static let untitled = "Untitled"
        static let by = "by"
        static let published = "Published"
        static let publisher = "Publisher"
        static let subjects = "Subjects"
        static let title = "Title"
        static let authors = "Authors"
        static let isbn = "ISBN"
        static let noMetadataAvailable = "No metadata available"
        static let noBookCoverAvailable = "No book cover available"
        static let bookCover = "Book cover"
        static let bookDetails = "Book Details"
        static let metadata = "Metadata"
        static let description = "Description"
        static let notes = "Notes"
        static let bookInfo = "Book Info"
        static let editBook = "Edit Book"
        static let share = "Share"
        static let edit = "Edit"
        static let delete = "Delete"
        static let deleteBook = "Delete Book"
        static let cancel = "Cancel"
        static let save = "Save"
        static let copied = "Copied"
        static let copy = "Copy"
        static let notAvailable = "Not available"
        static let bookActions = "Book actions"
        static let removeBookConfirmation = "Remove \"%@\" from your catalog? This cannot be undone."
        static let addYourThoughts = "Add your thoughts, highlights, or reminders about this book…"
        static let valueNotAvailable = "Not available"
        static let searchByTitleAuthorISBNSubject = "Search by title, author, ISBN, or subject"
        static let searchPlaceholderISBN = "e.g. 978-0-385-50420-5"
        static let searchPlaceholderAuthor = "e.g. Jane Austen"
        static let searchPlaceholderTitle = "e.g. Pride and Prejudice"
        static let searchPlaceholderSubject = "e.g. love, science, fiction"
        static let noResultsForSubject = "No books found for subject \"%@\""
        static let noResultsForSearchType = "No books found for %@ \"%@\""
        static let searchTypeISBN = "ISBN"
        static let searchTypeAuthor = "Author"
        static let searchTypeTitle = "Title"
        static let searchTypeSubject = "Subject"
        static let searchTypePicker = "Search type"
        static let searchTypePickerHint = "Choose how to search for books"
        
        // Collection
        static let yourCollection = "Your Collection"
        static let totalBooks = "Total books"
        static let bookSubjects = "Book Subjects"
        static let recentlyAdded = "Recently Added"
        static let recentlyAddedHint = "Shows the most recently added books in your collection"
        
        // Saved Book
        static let myBooks = "My Books"
        static let booksVertical = "Books vertical"
        static let grid = "Grid"
        static let list = "List"
        static let unfavorite = "Unfavorite"
        static let favorite = "Favorite"
        static let scanAndAddBooksToSeeThemHere = "Scan and add books to see them here."
        static let thisBookAlreadyExistInYourList = "This book is already in your list."
        
        // Editable
        static let noMetdataAvailable = "No metadata available"
        static let addYourThoughtsHighlights = "Add your thoughts, highlights, or reminders about this book…"

        static func searchPlaceholder(for type: SearchType) -> String {
            switch type {
            case .isbn: return "e.g. 978-0-385-50420-5"
            case .author: return "e.g. Jane Austen"
            case .title: return "e.g. Pride and Prejudice"
            case .subject: return "e.g. love, science, fiction"
            }
        }

        static func noResults(for searchType: SearchType, term: String) -> String {
            searchType == .subject
                ? "No books found for subject \"\(term)\""
                : "No books found for \(searchType.rawValue) \"\(term)\""
        }

        static func searchTypeLabel(for type: SearchType) -> String {
            type.rawValue
        }

        // Shared dynamic helpers
        static func viewSavedBooks(count: Int) -> String {
            "View Saved Books (\(count))"
        }

        static func version(_ version: String) -> String {
            "Version \(version)"
        }

        static func noResultsDescription(for searchText: String) -> String {
            "No books match \"\(searchText)\". Try a different or shorter search term, check your spelling, or search by author, title, ISBN, or subject."
        }

        static func noBooksFound(for searchType: String, term: String) -> String {
            "No books found for \(searchType) \"\(term)\""
        }

        static func deleteBookConfirmation(_ title: String) -> String {
            "Remove \"\(title)\" from your catalog? This cannot be undone."
        }

        static func bookAdded(_ title: String) -> String {
            "\"\(title)\" added to your list."
        }

        static func couldNotSaveBook(_ error: String) -> String {
            "Could not save book: \(error)"
        }

    }

    struct Accessibility {
        static let scannerViewLabel = "Live camera view for barcode scanning"
        static let scannerViewHint = "Align the code inside the green frame to scan"
        static let closeScanner = "Close scanner"
        static let closeScannerHint = "Returns to the previous screen"
        static let scannedCode = "Scanned code"
        static let lookingUpBook = "Looking up book details"
        static let addToMyBooksHint = "Adds this book to your saved list"
        static let lookupFailed = "Lookup failed"
        static let alignCodeHint = "Move your device until the barcode is centered"
        static let startScanningABook = "Start scanning a book"
        static let startScanningHint = "Opens the camera to scan a barcode or QR code"
        static let browseBooks = "Browse Books"
        static let browseBooksHint = "Opens subject browse using Open Library API"
        static let viewSavedBooks = "View saved books"
        static let viewSavedBooksHint = "Opens your saved library"
        static let shareBookListHint = "Share your book list with friends or family"
        static let noBooksYet = "No books yet"
        static let noBooksYetHint = "Scan and add books to see them here"
        static let closeLibrary = "Close library"
        static let editSavedBooks = "Edit saved books"
        static let shareBookList = "Share book list"
        static let switchToGridView = "Switch to grid view"
        static let switchToListView = "Switch to list view"
        static let openBookCover = "Book cover"
        static let copiesISBN = "Copies ISBN to clipboard"
        static let bookActions = "Book actions"
        static let skipOnboarding = "Skip onboarding"
        static let skipOnboardingHint = "Dismisses the onboarding and goes to the main screen"
        static let bookDetails = "Book details"
        static let bookCover = "Book cover"
        static let bookCoverNoAvailable = "No book cover available"
        static let copiesISBNtoClipboard = "Copies ISBN to clipboard"
        
        static func savedBooks(_ count: Int) -> String {
            "\(count) books"
        }
        static let bookDetailsHint = "Shows more information about the book."
    }

    struct Icons {
        static let close = "xmark.circle.fill"
        static let add = "plus.circle.fill"
        static let barcode = "barcode"
        static let magnifyingGlass = "magnifyingglass"
        static let calendar = "calendar"
        static let cameraViewfinder = "camera.viewfinder"
        static let tag = "tag"
        static let booksVertical = "books.vertical"
        static let squareGrid2x2 = "square.grid.2x2"
        static let listBullet = "list.bullet"
        static let bookClosed = "book.closed"
        static let bookClosedFill = "book.closed.fill"
        static let booksVerticalFill = "books.vertical.fill"
        static let cameraViewfinderFill = "camera.viewfinder"
        static let tagFill = "tag.fill"
        static let squareAndArrowUp = "square.and.arrow.up"
        static let heart = "heart"
        static let heartFill = "heart.fill"
        static let heartSlash = "heart.slash"
        static let trash = "trash"
        static let pencil = "pencil"
        static let ellipsisCircle = "ellipsis.circle"
        static let docOnDoc = "doc.on.doc"
        static let checkmarkCircleFill = "checkmark.circle.fill"
        static let book = "book"
        static let search = "magnifyingglass"
        static let share = "square.and.arrow.up"
        static let favorite = "heart"
        static let unfavorite = "heart.slash"
        static let grid = "square.grid.2x2"
        static let list = "list.bullet"
    }

    struct Alerts {
        static let cameraAccessNeeded = "Camera Access Needed"
        static let cameraAccessMessage = "Enable camera permissions in Settings to scan barcodes and QR codes."
        static let ok = "OK"
        static let deleteBook = "Delete Book"
        static let cancel = "Cancel"
    }
}
