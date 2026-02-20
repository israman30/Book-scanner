//
//  BookScannerView.swift
//  Book Scanner
//
//  Created by AI Assistant on 2/19/26.
//

import SwiftUI
import AVFoundation

struct BookScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var scannedCode: String?
    @State private var permissionDenied = false
    @State private var lookupState: LookupState = .idle
    @State private var book: BookItem?
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            CameraScannerView(onScan: { code in
                scannedCode = code
                lookupState = .loading
                book = nil
                errorMessage = nil
                fetchBook(for: code)
            }, onPermissionDenied: {
                permissionDenied = true
            })
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.green, lineWidth: 2)
                    .frame(width: 240, height: 240)
                    .shadow(color: .green.opacity(0.6), radius: 8)
            }
            .ignoresSafeArea()

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
                    BookLookupSection(state: lookupState, book: book, errorMessage: errorMessage)
                        .padding(.bottom, 20)
                } else {
                    Text("Align the code in the frame")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.9))
                        .padding(.bottom, 40)
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
    }

    private func fetchBook(for code: String) {
        BookService.search(isbn: code) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let item):
                    self.book = item
                    self.lookupState = .loaded
                case .failure(let message):
                    self.errorMessage = message
                    self.lookupState = .failed
                }
            }
        }
    }
}

enum LookupState {
    case idle
    case loading
    case loaded
    case failed
}

struct BookLookupSection: View {
    let state: LookupState
    let book: BookItem?
    let errorMessage: String?

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
                }
            case .loaded:
                if let book {
                    BookDetailCard(book: book)
                }
            case .failed:
                Text(errorMessage ?? "No book found")
                    .font(.subheadline)
                    .foregroundStyle(.red.opacity(0.9))
                    .padding(12)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .animation(.easeInOut, value: state)
    }
}

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
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

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

final class ScannerViewController: UIViewController {
    var onCodeDetected: ((String) -> Void)?
    var onPermissionDenied: (() -> Void)?

    private let session = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var isConfigured = false
    private var didReturnResult = false

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
