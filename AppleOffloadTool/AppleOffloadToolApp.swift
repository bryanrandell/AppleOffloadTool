//
//  AppleOffloadToolApp.swift
//  AppleOffloadTool
//
//  Created by Bryan RANDELL on 05/01/2025.
//

import SwiftUI
import ImageCaptureCore

@main
struct iphone_offload_toolApp: App {
    @StateObject private var deviceManager = DeviceManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(deviceManager)
//                .onAppear{
//                    deviceManager.registerFileProviderDomain()
//                }
        }
    }
}
