//
//  phoreApp.swift
//  phore
//
//  Created by Zane on 1/23/23.
//

import SwiftUI

@main
struct phoreApp: App {
    @Environment(\.scenePhase) var scenePhase
    
    @StateObject private var persistenceController = PersistenceController.shared
    
    let photoLibraryService = PhotoLibraryService()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(photoLibraryService)
        }
            .onChange(of: scenePhase) { _ in
                persistenceController.save()
            }
    }
}
