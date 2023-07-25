//
//  ZeroTVApp.swift
//  ZeroTV
//
//  Created by Jeremy Blaker on 7/14/23.
//

import SwiftUI

@main
struct ZeroTVApp: App {
    @StateObject private var modelData = ModelData()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(modelData)
        }
    }
}

struct Platform {

    static var isSimulator: Bool {
        return TARGET_OS_SIMULATOR != 0
    }

}
