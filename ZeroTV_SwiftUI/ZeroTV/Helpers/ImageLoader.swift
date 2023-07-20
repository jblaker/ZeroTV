//
//  ImageLoader.swift
//  SwiftUIPlayer
//
//  Copyright © 2023 Brightcove, Inc. All rights reserved.
//

import Foundation
import Combine

class ImageLoader: ObservableObject {
    @Published var data = Data()

    init(url: URL?) {
        guard let url = url else {
            return
            
        }
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data, self != nil else {
                return
            }
            DispatchQueue.main.async { [weak self] in
                self?.data = data
            }
        }
        task.resume()
    }
}
