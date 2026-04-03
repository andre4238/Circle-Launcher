//
//  SettingsView.swift
//  Circle Launcher
//
//  Created by André Lobach on 03.04.26.
//

import SwiftUI
import SwiftData
import AppKit
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \AppItem.position) private var apps: [AppItem]
    
    @State private var selectedApp: AppItem?
    @State private var showingAddSheet = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Circle Launcher Apps")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: { showingAddSheet = true }) {
                    Label("Add App", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            
            Divider()
            
            // App list
            if apps.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "app.dashed")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    
                    Text("No apps configured")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    Text("Click the + button to add apps to your launcher")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(selection: $selectedApp) {
                    ForEach(apps) { app in
                        AppRow(app: app)
                            .tag(app)
                            .contextMenu {
                                Button("Move Up") {
                                    moveUp(app)
                                }
                                .disabled(app.position == 0)
                                
                                Button("Move Down") {
                                    moveDown(app)
                                }
                                .disabled(app.position == apps.count - 1)
                                
                                Divider()
                                
                                Button("Remove", role: .destructive) {
                                    removeApp(app)
                                }
                            }
                    }
                    .onMove(perform: moveItems)
                    .onDelete(perform: deleteItems)
                }
                .listStyle(.inset)
            }
            
            Divider()
            
            // Footer
            HStack {
                if let selected = selectedApp {
                    Text("Selected: \(selected.name)")
                        .foregroundStyle(.secondary)
                } else {
                    Text("Tip: Press ⌥Space to open the launcher")
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button(role: .destructive, action: { 
                    if let selected = selectedApp {
                        removeApp(selected)
                    }
                }) {
                    Label("Remove", systemImage: "trash")
                }
                .disabled(selectedApp == nil)
            }
            .padding()
        }
        .sheet(isPresented: $showingAddSheet) {
            AddAppSheet(onAdd: { name, bundleID in
                addApp(name: name, bundleID: bundleID)
            })
        }
    }
    
    private func addApp(name: String, bundleID: String) {
        let newPosition = apps.map { $0.position }.max() ?? -1
        let newApp = AppItem(name: name, bundleIdentifier: bundleID, position: newPosition + 1)
        modelContext.insert(newApp)
        
        do {
            try modelContext.save()
        } catch {
            print("Error saving app: \(error)")
        }
    }
    
    private func removeApp(_ app: AppItem) {
        modelContext.delete(app)
        
        // Reorder remaining apps
        let remainingApps = apps.filter { $0.id != app.id }.sorted { $0.position < $1.position }
        for (index, remainingApp) in remainingApps.enumerated() {
            remainingApp.position = index
        }
        
        selectedApp = nil
        
        do {
            try modelContext.save()
        } catch {
            print("Error removing app: \(error)")
        }
    }
    
    private func moveUp(_ app: AppItem) {
        guard app.position > 0 else { return }
        
        if let otherApp = apps.first(where: { $0.position == app.position - 1 }) {
            let temp = app.position
            app.position = otherApp.position
            otherApp.position = temp
            
            do {
                try modelContext.save()
            } catch {
                print("Error moving app: \(error)")
            }
        }
    }
    
    private func moveDown(_ app: AppItem) {
        guard app.position < apps.count - 1 else { return }
        
        if let otherApp = apps.first(where: { $0.position == app.position + 1 }) {
            let temp = app.position
            app.position = otherApp.position
            otherApp.position = temp
            
            do {
                try modelContext.save()
            } catch {
                print("Error moving app: \(error)")
            }
        }
    }
    
    private func moveItems(from source: IndexSet, to destination: Int) {
        var updatedApps = apps
        updatedApps.move(fromOffsets: source, toOffset: destination)
        
        for (index, app) in updatedApps.enumerated() {
            app.position = index
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Error reordering apps: \(error)")
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(apps[index])
        }
        
        // Reorder remaining
        let remainingApps = apps.enumerated().filter { !offsets.contains($0.offset) }.map { $0.element }
        for (index, app) in remainingApps.enumerated() {
            app.position = index
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Error deleting apps: \(error)")
        }
    }
}

struct AppRow: View {
    let app: AppItem
    
    var body: some View {
        HStack(spacing: 12) {
            Image(nsImage: app.icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(app.name)
                    .font(.headline)
                
                Text(app.bundleIdentifier)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text("#\(app.position + 1)")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.secondary.opacity(0.1))
                .clipShape(Capsule())
        }
        .padding(.vertical, 4)
    }
}

struct AddAppSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var onAdd: (String, String) -> Void
    
    @State private var appName = ""
    @State private var bundleIdentifier = ""
    @State private var selectedAppURL: URL?
    @State private var showingFilePicker = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Add Application")
                .font(.title2)
                .fontWeight(.semibold)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 16) {
                // App selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Application")
                        .font(.headline)
                    
                    HStack {
                        if let url = selectedAppURL {
                            Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                                .resizable()
                                .frame(width: 32, height: 32)
                            
                            Text(url.lastPathComponent.replacingOccurrences(of: ".app", with: ""))
                                .lineLimit(1)
                        } else {
                            Image(systemName: "app.dashed")
                                .frame(width: 32, height: 32)
                                .foregroundStyle(.secondary)
                            
                            Text("No app selected")
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Button("Choose...") {
                            showFilePicker()
                        }
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                // App name
                VStack(alignment: .leading, spacing: 8) {
                    Text("Display Name")
                        .font(.headline)
                    
                    TextField("App Name", text: $appName)
                        .textFieldStyle(.roundedBorder)
                }
                
                // Bundle ID
                VStack(alignment: .leading, spacing: 8) {
                    Text("Bundle Identifier")
                        .font(.headline)
                    
                    TextField("com.example.app", text: $bundleIdentifier)
                        .textFieldStyle(.roundedBorder)
                        .disabled(true)
                }
            }
            .padding()
            
            Spacer()
            
            Divider()
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("Add") {
                    onAdd(appName, bundleIdentifier)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(appName.isEmpty || bundleIdentifier.isEmpty)
            }
            .padding()
        }
        .frame(width: 500, height: 400)
    }
    
    private func showFilePicker() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [UTType.applicationBundle]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                selectedAppURL = url
                
                // Extract bundle info
                if let bundle = Bundle(url: url) {
                    if let bundleID = bundle.bundleIdentifier {
                        bundleIdentifier = bundleID
                    }
                    
                    if let displayName = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String {
                        appName = displayName
                    } else if let name = bundle.object(forInfoDictionaryKey: "CFBundleName") as? String {
                        appName = name
                    } else {
                        appName = url.deletingPathExtension().lastPathComponent
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: AppItem.self, inMemory: true)
        .frame(width: 600, height: 400)
}
