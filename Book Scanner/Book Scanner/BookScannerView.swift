//
//  BookScannerView.swift
//  Book Scanner
//
//  Created by AI Assistant on 2/19/26.
//

import SwiftUI
import AVFoundation
import UIKit
import CoreData

/// Full-screen scanner experience that reads barcodes/QR codes and looks up
/// book details, exposing add-to-library flow when a match is found.
/// Saves books to Core Data when the user adds them.
struct BookScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @State private var scannedCode: String?
    @State private var permissionDenied = false
    @State private var lookupState: LookupState = .idle
    @State private var book: BookItem?
    @State private var errorMessage: String?
    @State private var showAddMessage = false
    @State private var addMessage = ""

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            CameraScannerView(onScan: { code in
                scannedCode = code
                lookupState = .loading
                book = nil
                errorMessage = nil
                announce("Code captured. Looking up book details.")
                fetchBook(for: code)
            }, onPermissionDenied: {
                permissionDenied = true
            })
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.green, lineWidth: 2)
                    .frame(width: 300, height: 240)
                    .shadow(color: .green.opacity(0.6), radius: 8)
                    .accessibilityHidden(true)
            }
            .ignoresSafeArea()
            .accessibilityLabel("Live camera view for barcode scanning")
            .accessibilityHint("Align the code inside the green frame to scan")

            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(12)
                    }
                    .accessibilityLabel("Close scanner")
                    .accessibilityHint("Returns to the previous screen")
                    Spacer()
                }
                Spacer()
                if let scannedCode {
                    Text("Scanned: \(scannedCode)")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        .padding(.bottom, 40)
                        .accessibilityLabel("Scanned code")
                        .accessibilityValue(scannedCode)
                    BookLookupSection(
                        state: lookupState,
                        book: book,
                        errorMessage: errorMessage,
                        onAdd: addBookToLibrary
                    )
                    .padding(.bottom, 20)
                } else {
                    Text("Align the code in the frame")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.9))
                        .padding(.bottom, 40)
                        .multilineTextAlignment(.center)
                        .accessibilityHint("Move your device until the barcode is centered")
                }
            }
            .padding()
        }
        .alert("Camera Access Needed", isPresented: $permissionDenied) {
            Button("OK", role: .cancel) {
                dismiss()
            }
        } message: {
            Text("Enable camera permissions in Settings to scan barcodes and QR codes.")
        }
        .alert(addMessage, isPresented: $showAddMessage) {
            Button("OK", role: .cancel) { }
        }
    }

    /// Resolves a scanned barcode/QR string into book metadata using Open Library.
    /// Updates lookup UI state on the main thread as results arrive.
    private func fetchBook(for code: String) {
        BookService.search(isbn: code) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let item):
                    self.book = item
                    self.lookupState = .loaded
                    let title = item.volumeInfo.title ?? "book"
                    announce("Book found: \(title)")
                case .failure(let message):
                    self.errorMessage = message
                    self.lookupState = .failed
                    announce(message)
                }
            }
        }
    }

    /// Converts an API `BookItem` into the app's saved model, persists to Core Data,
    /// and prevents duplicate entries based on ISBN before showing a confirmation alert.
    private func addBookToLibrary(_ item: BookItem) {
        let newEntry = SavedBook(from: item)

        if let isbn = newEntry.isbn {
            let request = BookEntity.fetchRequest()
            request.predicate = NSPredicate(format: "isbn == %@", isbn)
            request.fetchLimit = 1
            do {
                let existing = try viewContext.fetch(request)
                if !existing.isEmpty {
                    addMessage = "This book is already in your list."
                    showAddMessage = true
                    announce(addMessage)
                    return
                }
            } catch {
                print("Duplicate check failed: \(error)")
            }
        }

        _ = BookEntity.create(from: newEntry, in: viewContext)
        do {
            try viewContext.save()
            addMessage = "\"\(newEntry.title)\" added to your list."
        } catch {
            addMessage = "Could not save book: \(error.localizedDescription)"
        }
        showAddMessage = true
        announce(addMessage)
    }

    /// Announces important state changes for VoiceOver users.
    private func announce(_ message: String) {
        UIAccessibility.post(notification: .announcement, argument: message)
    }
}

/// UI state machine for the lookup panel shown under the live camera feed.
enum LookupState {
    case idle
    case loading
    case loaded
    case failed
}

/// Renders a lookup result section under the scanner: loading indicator,
/// fetched book details, or an error message. Accepts a callback to add books.
struct BookLookupSection: View {
    let state: LookupState
    let book: BookItem?
    let errorMessage: String?
    var onAdd: ((BookItem) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            switch state {
            case .idle:
                EmptyView()
            case .loading:
                HStack(spacing: 12) {
                    ProgressView()
                        .progressViewStyle(.circular)
                    Text("Looking up book...")
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .accessibilityLabel("Looking up book details")
                }
            case .loaded:
                if let book {
                    BookDetailCard(book: book)
                    Button {
                        onAdd?(book)
                    } label: {
                        Label("Add to My Books", systemImage: "plus.circle.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.white.opacity(0.1))
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.top, 8)
                    .accessibilityHint("Adds this book to your saved list")
                }
            case .failed:
                Text(errorMessage ?? "No book found")
                    .font(.subheadline)
                    .foregroundStyle(.red.opacity(0.9))
                    .padding(12)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    .accessibilityLabel("Lookup failed")
                    .accessibilityValue(errorMessage ?? "No book found")
            }
        }
        .animation(.easeInOut, value: state)
    }
}

/// Minimal card showing the key details we get back from Open Library.
struct BookDetailCard: View {
    let book: BookItem

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(book.volumeInfo.title ?? "Unknown Title")
                .font(.headline)
                .foregroundStyle(.white)

            if let authors = book.volumeInfo.authors?.joined(separator: ", ") {
                Text(authors)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
            }

            if let published = book.volumeInfo.publishedDate {
                Text("Published: \(published)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }

            if let firstIdentifier = book.volumeInfo.industryIdentifiers?.first?.identifier {
                Text("ISBN: \(firstIdentifier)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .padding(12)
        .background(
            Color.black.opacity(0.35),
            in: RoundedRectangle(cornerRadius: 12)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Book details")
        .accessibilityValue(accessibilitySummary)
    }

    private var accessibilitySummary: String {
        var parts: [String] = []
        if let title = book.volumeInfo.title {
            parts.append("Title \(title)")
        }
        if let authors = book.volumeInfo.authors?.joined(separator: ", ") {
            parts.append("Authors \(authors)")
        }
        if let published = book.volumeInfo.publishedDate {
            parts.append("Published \(published)")
        }
        if let firstIdentifier = book.volumeInfo.industryIdentifiers?.first?.identifier {
            parts.append("ISBN \(firstIdentifier)")
        }
        return parts.joined(separator: ". ")
    }
}

/// SwiftUI wrapper that embeds the UIKit-based scanner controller.
/// Emits scanned code strings and signals if camera permission is denied.
struct CameraScannerView: UIViewControllerRepresentable {
    var onScan: (String) -> Void
    var onPermissionDenied: () -> Void

    func makeUIViewController(context: Context) -> ScannerViewController {
        let controller = ScannerViewController()
        controller.onCodeDetected = onScan
        controller.onPermissionDenied = onPermissionDenied
        return controller
    }

    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) { }
}

/// UIKit controller that configures an AVCapture session to detect barcodes
/// and QR codes, forwarding results back to SwiftUI via callbacks.
class ScannerViewController: UIViewController {
    var onCodeDetected: ((String) -> Void)?
    var onPermissionDenied: (() -> Void)?

    private let session = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    var isConfigured = false
    var didReturnResult = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        checkPermissionAndConfigure()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        session.stopRunning()
    }

    private func checkPermissionAndConfigure() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    granted ? self.configureSession() : self.handlePermissionDenied()
                }
            }
        default:
            handlePermissionDenied()
        }
    }

    private func handlePermissionDenied() {
        onPermissionDenied?()
    }

    private func configureSession() {
        guard !isConfigured else {
            session.startRunning()
            return
        }

        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
              session.canAddInput(videoInput) else {
            return
        }

        configureFocus(for: videoDevice)

        session.beginConfiguration()
        session.addInput(videoInput)

        let metadataOutput = AVCaptureMetadataOutput()
        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [
                .qr,
                .ean8,
                .ean13,
                .pdf417,
                .code128,
                .upce,
                .aztec
            ]
        }

        session.commitConfiguration()

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.insertSublayer(previewLayer, at: 0)
        self.previewLayer = previewLayer

        isConfigured = true
        Task.detached(priority: .background) {
            await self.session.startRunning()
        }
    }

    /// Centers the camera focus/exposure for barcode scanning without interrupting capture.
    private func configureFocus(for device: AVCaptureDevice) {
        do {
            try device.lockForConfiguration()

            if device.isFocusPointOfInterestSupported {
                device.focusPointOfInterest = CGPoint(x: 0.5, y: 0.5)
            }
            
            if device.isFocusModeSupported(.continuousAutoFocus) {
                device.focusMode = .continuousAutoFocus
            }

            if device.isExposurePointOfInterestSupported {
                device.exposurePointOfInterest = CGPoint(x: 0.5, y: 0.5)
            }
            
            if device.isExposureModeSupported(.continuousAutoExposure) {
                device.exposureMode = .continuousAutoExposure
            }

            device.unlockForConfiguration()
        } catch {
            // If configuration fails, continue with default focus settings.
            return
        }
    }
}

extension ScannerViewController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard !didReturnResult,
              let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let value = object.stringValue else { return }

        didReturnResult = true
        onCodeDetected?(value)
        session.stopRunning()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.didReturnResult = false
            Task.detached(priority: .background) {
                await self?.session.startRunning()
            }
        }
    }
}
