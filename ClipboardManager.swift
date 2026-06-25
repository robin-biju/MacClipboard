import Foundation
import AppKit

class ClipboardManager: ObservableObject {
    @Published var history: [String] = []
    
    private let pasteboard = NSPasteboard.general
    private var lastChangeCount: Int
    private var timer: Timer?
    private let userDefaultsKey = "ClipboardHistory"
    private let maxHistoryCount = 50
    
    init() {
        self.lastChangeCount = pasteboard.changeCount
        loadHistory()
        startMonitoring()
    }
    
    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkForChanges()
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    private func checkForChanges() {
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount
        
        // 1. Check for standard concealed / transient types (Password Managers)
        let types = pasteboard.types ?? []
        let isConcealed = types.contains(NSPasteboard.PasteboardType("org.nspasteboard.ConcealedType"))
        let isTransient = types.contains(NSPasteboard.PasteboardType("org.nspasteboard.TransientType"))
        
        guard !isConcealed && !isTransient else { return }
        
        // 2. Check for explicit app exclusions
        let excludedAppsString = UserDefaults.standard.string(forKey: "excludedApps") ?? ""
        let excludedApps = excludedAppsString.isEmpty ? [] : excludedAppsString.components(separatedBy: ",")
        
        if let frontmost = NSWorkspace.shared.frontmostApplication,
           let appName = frontmost.localizedName {
            if excludedApps.contains(where: { $0.caseInsensitiveCompare(appName) == .orderedSame }) {
                return
            }
        }
        
        if let newString = pasteboard.string(forType: .string) {
            let trimmed = newString.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return }
            
            DispatchQueue.main.async {
                self.addItemsToHistory(item: newString)
            }
        }
    }
    
    private func addItemsToHistory(item: String) {
        // Remove the item if it already exists to avoid duplicates
        history.removeAll { $0 == item }
        
        // Add to the beginning
        history.insert(item, at: 0)
        
        // Keep only recent items
        if history.count > maxHistoryCount {
            history = Array(history.prefix(maxHistoryCount))
        }
        
        saveHistory()
    }
    
    func copyToClipboard(item: String) {
        pasteboard.clearContents()
        pasteboard.setString(item, forType: .string)
        // Update change count so we don't re-save what we just copied
        lastChangeCount = pasteboard.changeCount
        
        // Move item to the top
        addItemsToHistory(item: item)
    }
    
    func clearHistory() {
        history.removeAll()
        saveHistory()
    }
    
    func removeItem(_ item: String) {
        history.removeAll { $0 == item }
        saveHistory()
    }
    
    private func saveHistory() {
        UserDefaults.standard.set(history, forKey: userDefaultsKey)
    }
    
    private func loadHistory() {
        if let savedHistory = UserDefaults.standard.stringArray(forKey: userDefaultsKey) {
            history = savedHistory
        }
    }
}
