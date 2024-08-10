//
//  ContentView.swift
//  phore
//
//  Created by Zane on 1/23/23.
//

import SwiftUI

struct ContentView: View {
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
               // useless for rn lol
           }
           self.selection = $0
       }
    )}
    
//    init() {
//        let transparentAppearence = UITabBarAppearance()
//        transparentAppearence.configureWithOpaqueBackground()
//        UITabBar.appearance().standardAppearance = transparentAppearence
//    }
    
    var body: some View {
        TabView(selection: handler) {
            PhotoLibraryView()
                .tabItem {
                    Label("Photos", systemImage: "photo.fill.on.rectangle.fill")
                }
                .tag(Tab.photos)
            
            CollectionsView()
                .tabItem {
                    Label("Collections", systemImage: "rectangle.stack.fill")
                }
                .tag(Tab.collections)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
