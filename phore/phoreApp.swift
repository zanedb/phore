//
//  phoreApp.swift
//  phore
//
//  Created by Zane on 8/10/24.
//

import SwiftUI

@main
struct phoreApp: App {
    var library = LibraryService()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(library)
        }
    }
}
