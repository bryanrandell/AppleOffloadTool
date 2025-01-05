//
//  ContentView.swift
//  AppleOffloadTool
//
//  Created by Bryan RANDELL on 05/01/2025.
//

import SwiftUI
import AppKit  // for NSOpenPanel

struct ContentView: View {
    @EnvironmentObject var deviceManager: DeviceManager
    
    // A local state to hold the user’s desired prefix:
    @State private var customPrefix: String = ""
    
    var body: some View {
        VStack(spacing: 20) {
            // List the discovered devices
            List(deviceManager.discoveredDevices, id: \.self) { device in
                Button {
                    deviceManager.selectDevice(device)
                } label: {
                    Text(device.name ?? "Unnamed Device")
                }
            }
            
            if let camera = deviceManager.selectedCamera {
                Text("Selected: \(camera.name ?? "Unknown")")
            } else {
                Text("No camera selected.")
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            HStack {
                Text("File Prefix:")
                TextField("Enter prefix", text: $customPrefix)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 150)
                
                Button("Pick Folder & Download") {
                    // 1) Let user pick folder
                    if let folderURL = pickFolderUsingNSOpenPanel() {
                        // 2) Pass folderURL + prefix to deviceManager
                        print("Picked folder: \(folderURL.path)")
                        deviceManager.downloadAllItems(filePathURL: folderURL, fileNamePrefix: customPrefix)
                    }
                }
            }
        }
        .padding()
        .frame(minWidth: 500, minHeight: 400)
    }
    
    /// Presents an NSOpenPanel for picking a directory
    private func pickFolderUsingNSOpenPanel() -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.title = "Select a download folder"
        
        return panel.runModal() == .OK ? panel.url : nil
    }
}

#Preview {
    ContentView()
        .environmentObject(DeviceManager())
}

