//
//  RemoteGPIOApp.swift
//  RemoteGPIO
//
//  Created by Thibault Vieux on 29/09/2024.
//

import SwiftUI

@main
struct RemoteGPIOApp: App {
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onChange(of: scenePhase) { oldPhase, newPhase in
                    if newPhase == .active {
                        NotificationCenter.default.post(name: .appDidBecomeActive, object: nil)
                    }
                }
        }
    }
}

extension Notification.Name {
    static let appDidBecomeActive = Notification.Name("appDidBecomeActive")
}
