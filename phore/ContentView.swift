//
//  ContentView.swift
//  phore
//
//  Created by Zane on 8/10/24.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var library: LibraryService
    @State private var selection: Tab = .photos
    
    enum Tab {
       case photos
       case collections
    }
    
    var handler: Binding<Tab> { Binding(
       get: { self.selection },
       set: {
           if $0 == self.selection {
               // double tap of Tab selector
               // TODO: scroll to bottom
           }
           self.selection = $0
       }
    )}
    
    var body: some View {
        TabView(selection: handler) {
            if library.notAuthorized {
                EmptyView()
            } else {
                LibraryView()
                    .tabItem {
                        Label("Photos", systemImage: "photo.fill.on.rectangle.fill")
                    }
                    .tag(Tab.photos)
            }
            
            VStack {
                Text("Collections view")
            }
                .tabItem {
                    Label("Collections", systemImage: "rectangle.stack.fill")
                }
                .tag(Tab.collections)
        }
            .environmentObject(library)
            .sheet(isPresented: $library.notAuthorized) {
                OnboardingView()
                    .interactiveDismissDisabled()
            }
    }
}

#Preview {
    ContentView()
}
