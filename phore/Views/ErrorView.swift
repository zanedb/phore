//
//  ErrorView.swift
//  phore
//
//  Created by Zane on 8/10/24.
//

import SwiftUI

struct ErrorView: View {
    var icon: String
    var title: String
    var subtitle: String
    
    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: icon)
                .foregroundColor(.blue.opacity(0.70))
                .font(.system(size: 48))
                .padding(.top, 50)
            Text(title)
                .padding(.top, 40)
                .bold()
                .foregroundColor(.primary)
                .font(.system(size: 22))
            Text(subtitle)
                .padding(.top, 10)
                .foregroundColor(.gray)
                .font(.system(size: 18))
        }
        .frame(maxHeight: .infinity)
    }
}

#Preview {
    ErrorView(icon: "moon.zzz", title: "No Friends", subtitle: "Go forth and make some.")
}
