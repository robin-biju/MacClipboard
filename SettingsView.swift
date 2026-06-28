import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @AppStorage("excludedApps") private var excludedAppsString: String = ""
    @AppStorage("maxHistoryCount") private var maxHistoryCount: Int = 50
    @State private var newApp: String = ""
    @State private var availableApps: [String] = []
    @State private var appPaths: [String: String] = [:]
    
    var excludedApps: [String] {
        guard !excludedAppsString.isEmpty else { return [] }
        return excludedAppsString.components(separatedBy: ",")
    }
    
    var suggestedApps: [String] {
        let trimmed = newApp.trimmingCharacters(in: .whitespaces).lowercased()
        guard !trimmed.isEmpty else { return [] }
        return availableApps.filter { $0.lowercased().contains(trimmed) && !excludedApps.contains($0) }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            
            Toggle("Launch MacClipboard at login", isOn: Binding(
                get: { SMAppService.mainApp.status == .enabled },
                set: { newValue in
                    do {
                        if newValue {
                            try SMAppService.mainApp.register()
                        } else {
                            try SMAppService.mainApp.unregister()
                        }
                    } catch {
                        print("Failed to change login item status: \(error)")
                    }
                }
            ))
            .toggleStyle(.switch)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 5) {
                Text("History Limit")
                    .font(.headline)
                Text("Maximum number of items to save in clipboard history.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Stepper(value: $maxHistoryCount, in: 1...500) {
                    Text("\(maxHistoryCount) items")
                }
            }
            
            Divider()
            
            Text("Excluded Applications")
                .font(.headline)
            Text("Copying from these apps will be ignored.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    TextField("E.g. Notes, Safari", text: $newApp)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onSubmit {
                            addApp(newApp)
                        }
                    Button("Add") {
                        addApp(newApp)
                    }
                    .disabled(newApp.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                
                if !suggestedApps.isEmpty {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            ForEach(suggestedApps, id: \.self) { app in
                                Button(action: {
                                    addApp(app)
                                }) {
                                    HStack {
                                        if let icon = getAppIcon(for: app) {
                                            icon.resizable().frame(width: 20, height: 20)
                                        } else {
                                            Image(systemName: "app").frame(width: 20, height: 20)
                                        }
                                        Text(app)
                                    }
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .onHover { hovering in
                                    if hovering {
                                        NSCursor.pointingHand.push()
                                    } else {
                                        NSCursor.pop()
                                    }
                                }
                                Divider()
                            }
                        }
                    }
                    .frame(maxHeight: 120)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
                }
            }
            .zIndex(1) // Keep suggestions above the list
            
            List {
                ForEach(excludedApps, id: \.self) { app in
                    HStack {
                        if let icon = getAppIcon(for: app) {
                            icon.resizable().frame(width: 24, height: 24)
                        } else {
                            Image(systemName: "app").frame(width: 24, height: 24)
                        }
                        Text(app)
                        Spacer()
                        Button(action: {
                            removeApp(app)
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(minHeight: 150)
            .border(Color.secondary.opacity(0.2))
            
            VStack(spacing: 4) {
                Text("Designed and developed by")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Link("Robin Biju", destination: URL(string: "https://robinbiju.com")!)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 10)
        }
        .padding()
        .frame(width: 350, height: 480)
        .onAppear {
            fetchInstalledApps()
        }
    }
    
    private func fetchInstalledApps() {
        DispatchQueue.global(qos: .userInitiated).async {
            let directories = [
                "/Applications",
                "/System/Applications",
                "/System/Applications/Utilities",
                NSHomeDirectory() + "/Applications"
            ]
            var paths = [String: String]()
            let fm = FileManager.default
            
            for dir in directories {
                if let urls = try? fm.contentsOfDirectory(at: URL(fileURLWithPath: dir), includingPropertiesForKeys: nil, options: .skipsHiddenFiles) {
                    for url in urls where url.pathExtension == "app" {
                        let name = url.deletingPathExtension().lastPathComponent
                        if paths[name] == nil {
                            paths[name] = url.path
                        }
                    }
                }
            }
            
            let sortedApps = Array(paths.keys).sorted()
            DispatchQueue.main.async {
                self.availableApps = sortedApps
                self.appPaths = paths
            }
        }
    }
    
    private func getAppIcon(for appName: String) -> Image? {
        if let path = appPaths[appName] {
            let icon = NSWorkspace.shared.icon(forFile: path)
            return Image(nsImage: icon)
        } else if let path = NSWorkspace.shared.fullPath(forApplication: appName) {
            let icon = NSWorkspace.shared.icon(forFile: path)
            return Image(nsImage: icon)
        }
        return nil
    }
    
    private func addApp(_ appName: String) {
        let trimmed = appName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        
        var current = excludedApps
        if !current.contains(trimmed) {
            current.append(trimmed)
            excludedAppsString = current.joined(separator: ",")
        }
        newApp = ""
    }
    
    private func removeApp(_ app: String) {
        var current = excludedApps
        current.removeAll { $0 == app }
        excludedAppsString = current.joined(separator: ",")
    }
}
