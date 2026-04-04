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
import ServiceManagement

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \AppItem.position) private var apps: [AppItem]
    
    @State private var selectedApp: AppItem?
    @State private var showingAddSheet = false
    @AppStorage("circleRadius") private var circleRadius: Double = 80.0  // Standard: 80
    @State private var launchAtLogin: Bool = LaunchAtLoginManager.shared.isEnabled
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with Tabs
            TabView {
                // Tab 1: Apps
                appsTab
                    .tabItem {
                        Label("Apps", systemImage: "app.badge")
                    }
                
                // Tab 2: Appearance
                appearanceTab
                    .tabItem {
                        Label("Appearance", systemImage: "slider.horizontal.3")
                    }
                
                // Tab 3: General
                generalTab
                    .tabItem {
                        Label("General", systemImage: "gearshape")
                    }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddAppSheet(onAdd: { name, bundleID in
                addApp(name: name, bundleID: bundleID)
            })
        }
    }
    
    // MARK: - Apps Tab
    
    private var appsTab: some View {
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
    }
    
    // MARK: - Appearance Tab
    
    private var appearanceTab: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Appearance Settings")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Customize the look and size of your radial launcher")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            
            Divider()
            
            // Settings Content
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Circle Size")
                                .font(.headline)
                            
                            Spacer()
                            
                            Text("\(Int(circleRadius)) px")
                                .font(.system(.body, design: .monospaced))
                                .foregroundStyle(.secondary)
                        }
                        
                        Slider(value: $circleRadius, in: 60...150, step: 5) {
                            Text("Circle Radius")
                        }
                        
                        HStack(spacing: 8) {
                            Button("Small") {
                                circleRadius = 60
                            }
                            .buttonStyle(.bordered)
                            
                            Button("Medium") {
                                circleRadius = 80
                            }
                            .buttonStyle(.bordered)
                            
                            Button("Large") {
                                circleRadius = 120
                            }
                            .buttonStyle(.bordered)
                            
                            Button("Extra Large") {
                                circleRadius = 150
                            }
                            .buttonStyle(.bordered)
                        }
                        .font(.caption)
                        
                        Text("Adjust the radius of the circle where app icons are positioned")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Circle Radius")
                } footer: {
                    Text("Changes will take effect the next time you open the launcher (⌥⌘)")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "circle")
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                            
                            Text("Current size: \(sizeDescription)")
                                .font(.subheadline)
                        }
                        
                        HStack(spacing: 4) {
                            Text("Total diameter:")
                            Text("\(Int(circleRadius * 2 + 80)) px")
                                .font(.system(.body, design: .monospaced))
                                .foregroundStyle(.blue)
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Preview Info")
                }
            }
            .formStyle(.grouped)
            
            Spacer()
            
            Divider()
            
            // Footer
            HStack {
                Text("💡 Tip: Larger circles work better with more apps")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Button("Reset to Default") {
                    circleRadius = 80
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
    }
    
    private var sizeDescription: String {
        switch circleRadius {
        case ..<70:
            return "Extra Small"
        case 70..<90:
            return "Small"
        case 90..<110:
            return "Medium"
        case 110..<130:
            return "Large"
        default:
            return "Extra Large"
        }
    }
    
    // MARK: - General Tab
    
    private var generalTab: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("General Settings")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Configure app behavior and system integration")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            
            Divider()
            
            // Settings Content
            Form {
                Section {
                    Toggle(isOn: $launchAtLogin) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Launch at Login")
                                .font(.headline)
                            
                            Text("Automatically start Circle Launcher when you log in")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .toggleStyle(.switch)
                    .onChange(of: launchAtLogin) { oldValue, newValue in
                        LaunchAtLoginManager.shared.isEnabled = newValue
                    }
                    
                    // Status-Anzeige
                    HStack {
                        Image(systemName: launchAtLogin ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(launchAtLogin ? .green : .secondary)
                        
                        Text("Status: \(LaunchAtLoginManager.shared.statusDescription)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                } header: {
                    Text("Startup")
                } footer: {
                    if #available(macOS 13.0, *) {
                        if SMAppService.mainApp.status == .requiresApproval {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("⚠️ Approval Required")
                                    .foregroundStyle(.orange)
                                    .fontWeight(.semibold)
                                
                                Text("Circle Launcher needs your permission to start at login. Please approve this in System Settings.")
                                    .foregroundStyle(.secondary)
                                
                                Button("Open Login Items Settings") {
                                    LaunchAtLoginManager.shared.openLoginItemsSettings()
                                }
                                .buttonStyle(.borderedProminent)
                            }
                            .padding(.top, 8)
                        } else {
                            Text("Circle Launcher will start automatically in the background when you log in to your Mac.")
                        }
                    }
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "keyboard")
                                .font(.title2)
                                .foregroundStyle(.blue)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Global Hotkey")
                                    .font(.headline)
                                
                                Text("Press ⌥⌘ (Option + Command)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                        }
                        
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("How to use:")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            HStack(spacing: 8) {
                                Label("Press & Hold", systemImage: "hand.tap")
                                Text("⌥⌘")
                                    .font(.system(.body, design: .monospaced))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.accentColor.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                            .font(.caption)
                            
                            HStack(spacing: 8) {
                                Label("Hover", systemImage: "cursorarrow.rays")
                                Text("Over your app")
                            }
                            .font(.caption)
                            
                            HStack(spacing: 8) {
                                Label("Release", systemImage: "hand.raised")
                                Text("Keys to launch")
                            }
                            .font(.caption)
                        }
                        .padding(.vertical, 4)
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Keyboard Shortcuts")
                } footer: {
                    Text("The global hotkey requires Accessibility permissions. Check in System Settings → Privacy & Security → Accessibility.")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundStyle(.blue)
                            
                            Text("About Circle Launcher")
                                .font(.headline)
                        }
                        
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 6) {
                            infoRow(label: "Version", value: "1.0.0")
                            infoRow(label: "Build", value: Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "Unknown")
                            infoRow(label: "macOS", value: "13.0+")
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("About")
                }
            }
            .formStyle(.grouped)
            
            Spacer()
        }
    }
    
    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .foregroundStyle(.primary)
        }
    }
    
    // MARK: - Helper Methods
    
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
