//
//  BookmarkButton.swift
//  ZeroTV
//
//  Created by Jeremy Blaker on 7/20/23.
//

import SwiftUI

struct BookmarkButton: View {
    @Binding var isBookmarked: Bool
    var body: some View {
        Button(action: {
            isBookmarked.toggle()
        }) {
            Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
        }
    }
}

struct BookmarkButton_Previews: PreviewProvider {
    static var previews: some View {
        BookmarkButton(isBookmarked: .constant(true))
    }
}
