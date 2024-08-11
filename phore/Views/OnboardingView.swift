//
//  OnboardingView.swift
//  phore
//
//  Created by Zane on 8/10/24.
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var library: LibraryService
    @State private var showNext = false
    @State private var showError = false
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                if (showNext) {
                    VStack(alignment: .leading) {
                        Spacer()
                        
                        Text("One more thing.")
                            .font(.largeTitle)
                            .bold()
                            .padding(.bottom)
                        
                        Button(action: {
                            library.requestAuthorization { error in
                                guard error != nil else { return }
                                showError = true
                            }
                        }, label: {
                            HStack() {
                                Image(systemName: showError ? "xmark.app" : "hand.raised.app")
                                    .font(.system(size: 32))
                                Text("Full Photo Library")
                                    .font(.system(size: 20))
                                    .bold()
                            }
                        })
                            .disabled(showError)
                        
                        // hacky workaround for positioning
                        // at some point i'll redo all of this lol
                        if UIDevice.current.userInterfaceIdiom == .pad {
                            Text("Without this permission, \(SSApp.name) is basically useless.")
                                .padding(.top, 1)
                        } else {
                            Text("Without this permission, \(SSApp.name) is basically useless.")
                                .padding(.top, 1)
                                .padding(.leading, -16)
                                .fillFrame(.horizontal)
                        }
                        
                        Spacer()
                    }
                } else {
                    HStack(alignment: .center) {
                        Spacer()
                        
                        Image(uiImage: UIImage(named: "AppIcon") ?? UIImage())
                            .resizable()
                            .frame(width: 144, height: 144)
                            .cornerRadius(25.263)
                        
                        Spacer()
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation {
                            showNext.toggle()
                        }
                    }, label: {
                        Text("Let’s go")
                            .foregroundColor(.primary)
                            .colorInvert()
                            .font(.system(size: 17))
                            .bold()
                            .padding(.vertical)
                            .fillFrame(.horizontal)
                    })
                        .background(.primary)
                        .cornerRadius(10)
                    
                    Text(markdown: "By continuing, you agree to our\n[Terms](https://zane.app/terms) and [Privacy Policy](https://zane.app/privacy).")
                        .multilineTextAlignment(.center)
                        .font(.system(size: 15))
                        .fontWeight(.light)
                        .padding(.top, 5)
                        .frame(maxWidth: 370) // Make it look good on iPad.
                }
            }
            .padding()
        }
    }
}

#Preview {
    OnboardingView()
}
