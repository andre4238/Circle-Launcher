//
//  ContentView.swift
//  Circle Launcher
//
//  Created by André Lobach on 03.04.26.
//

import SwiftUI

/// This view is not used in the final app since we run as a background agent (LSUIElement = YES)
/// The app interface is accessed through the menu bar icon and the radial menu panel
struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "circle.grid.2x2")
                .font(.system(size: 64))
                .foregroundStyle(.tint)
            
            Text("Circle Launcher")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("This app runs in the background")
                .font(.title3)
                .foregroundStyle(.secondary)
            
            Divider()
                .padding(.vertical)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "keyboard")
                    Text("Press ⌥Space to open the launcher")
                }
                
                HStack {
                    Image(systemName: "menubar.rectangle")
                    Text("Click the menu bar icon for settings")
                }
                
                HStack {
                    Image(systemName: "gearshape")
                    Text("Configure your apps in Settings")
                }
            }
            .font(.body)
        }
        .padding(40)
        .frame(minWidth: 400, minHeight: 300)
    }
}

#Preview {
    ContentView()
}
