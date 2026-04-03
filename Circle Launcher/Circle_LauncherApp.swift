//
//  Circle_LauncherApp.swift
//  Circle Launcher
//
//  Created by André Lobach on 03.04.26.
//

import SwiftUI

@main
struct Circle_LauncherApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
