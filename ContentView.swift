import SwiftUI

struct ContentView: View {
    @StateObject private var manager = ClipboardManager()
    @State private var selectedItem: String?
    @State private var hoveredItem: String?
    @State private var popoverItem: String?
    @State private var popoverTask: Task<Void, Never>?
    @State private var searchText: String = ""
    @FocusState private var isSearchFocused: Bool
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openWindow) private var openWindow
    
    private var filteredHistory: [String] {
        manager.history.filter { fuzzyMatch(query: searchText, text: $0) }
    }
    
    private func fuzzyMatch(query: String, text: String) -> Bool {
        if query.isEmpty { return true }
        let qChars = Array(query.lowercased())
        let tChars = Array(text.lowercased())
        var qIndex = 0
        for tChar in tChars {
            if qChars[qIndex] == tChar {
                qIndex += 1
                if qIndex == qChars.count { return true }
            }
        }
        return false
    }
    
    private var dynamicHeight: CGFloat {
        let count = filteredHistory.count
        if count == 0 { return 160 }
        
        let itemHeight: CGFloat = 33
        let headerHeight: CGFloat = 90
        let calculated = headerHeight + (CGFloat(count) * itemHeight)
        
        return min(calculated, 700)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Clipboard History")
                    .font(.headline)
                Spacer()
                Button(action: {
                    manager.clearHistory()
                    selectedItem = nil
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
                .help("Clear History")
                
                Button(action: {
                    NSApplication.shared.activate(ignoringOtherApps: true)
                    openWindow(id: "settings")
                    dismiss()
                }) {
                    Image(systemName: "gear")
                }
                .buttonStyle(.plain)
                .help("Settings")
                
                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    Image(systemName: "power")
                }
                .buttonStyle(.plain)
                .help("Quit")
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .focused($isSearchFocused)
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            if filteredHistory.isEmpty {
                Text(searchText.isEmpty ? "No copied items yet." : "No matching items.")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredHistory, id: \.self) { item in
                            HStack {
                                Text(item)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                    .foregroundColor(selectedItem == item ? .white : .primary)
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .contentShape(Rectangle())
                            .background(
                                selectedItem == item ? Color.accentColor :
                                (hoveredItem == item ? Color.gray.opacity(0.2) : Color.clear)
                            )
                            .onHover { isHovering in
                                if isHovering {
                                    self.hoveredItem = item
                                    self.selectedItem = item
                                    popoverTask = Task {
                                        try? await Task.sleep(nanoseconds: 3_000_000_000)
                                        if !Task.isCancelled {
                                            await MainActor.run {
                                                if self.hoveredItem == item {
                                                    self.popoverItem = item
                                                }
                                            }
                                        }
                                    }
                                } else {
                                    popoverTask?.cancel()
                                    if hoveredItem == item {
                                        hoveredItem = nil
                                        popoverItem = nil
                                    }
                                }
                            }
                            .onTapGesture {
                                selectedItem = item
                                manager.copyToClipboard(item: item)
                                dismiss()
                            }
                            .popover(isPresented: Binding(
                                get: { popoverItem == item },
                                set: { if !$0 { popoverItem = nil } }
                            )) {
                                ScrollView {
                                    Text(item)
                                        .padding()
                                        .textSelection(.enabled)
                                }
                                .frame(minWidth: 200, maxWidth: 500, minHeight: 50, maxHeight: 400)
                            }
                            
                            Divider()
                        }
                    }
                }
            }
        }
        .frame(width: 400, height: dynamicHeight)
        .onAppear {
            isSearchFocused = true
            if selectedItem == nil && !filteredHistory.isEmpty {
                selectedItem = filteredHistory.first
            }
        }
        .background(
            ZStack {
                // Return to Copy
                Button("") {
                    if let selected = selectedItem {
                        manager.copyToClipboard(item: selected)
                        dismiss()
                    }
                }
                .keyboardShortcut(.defaultAction)
                
                // Command+Delete to Remove
                Button("") {
                    if let selected = selectedItem, let index = manager.history.firstIndex(of: selected) {
                        manager.removeItem(selected)
                        
                        // Select the next available item
                        let items = manager.history.filter { fuzzyMatch(query: searchText, text: $0) }
                        if items.isEmpty {
                            selectedItem = nil
                        } else {
                            let nextIndex = min(index, items.count - 1)
                            selectedItem = items[nextIndex]
                        }
                    }
                }
                .keyboardShortcut(.delete, modifiers: .command)
                
                // Up Arrow
                Button("") {
                    let items = filteredHistory
                    if let current = selectedItem, let index = items.firstIndex(of: current) {
                        if index > 0 {
                            selectedItem = items[index - 1]
                        }
                    } else if !items.isEmpty {
                        selectedItem = items.first
                    }
                }
                .keyboardShortcut(.upArrow, modifiers: [])
                
                // Down Arrow
                Button("") {
                    let items = filteredHistory
                    if let current = selectedItem, let index = items.firstIndex(of: current) {
                        if index < items.count - 1 {
                            selectedItem = items[index + 1]
                        }
                    } else if !items.isEmpty {
                        selectedItem = items.first
                    }
                }
                .keyboardShortcut(.downArrow, modifiers: [])
            }
            .opacity(0)
        )
    }
}
