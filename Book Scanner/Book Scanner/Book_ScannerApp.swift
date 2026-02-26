//
//  Book_ScannerApp.swift
//  Book Scanner
//
//  Created by Israel Manzo on 2/19/26.
//

import SwiftUI

@main
struct Book_ScannerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.viewContext)
        }
    }
}
