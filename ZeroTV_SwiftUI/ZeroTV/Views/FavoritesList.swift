//
//  FavoritesList.swift
//  ZeroTV
//
//  Created by Jeremy Blaker on 7/19/23.
//

import SwiftUI

struct FavoritesList: View {
    @EnvironmentObject var modelData: ModelData

    var body: some View {
        ZStack {
            gradient
            NavigationView {
                List {
                    ForEach(modelData.favorites) { favorite in
                        NavigationLink {
                            StreamInfoList(streamingGroup: favorite)
                        } label: {
                            Text(favorite.name)
                        }
                    }
                }
                .navigationTitle("Favorites")
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}

struct FavoritesList_Previews: PreviewProvider {
    static var previews: some View {
        FavoritesList()
            .environmentObject(ModelData())
    }
}
