//
//  DownloadTask.swift
//  AppleOffloadTool
//
//  Created by Bryan RANDELL on 13/01/2025.
//

import Foundation
import ImageCaptureCore

enum TaskStatus: String, CaseIterable {
    case pending       = "Pending"
    case inProgress    = "In Progress"
    case done          = "Done"
    case failed        = "Failed"
}

struct DownloadTask: Identifiable {
    let id = UUID()                // For SwiftUI List
    let device: ICCameraDevice
    let folderURL: URL
    let prefix: String
    
    var status: TaskStatus = .pending
    var errorDescription: String? = nil  // If something fails, store message
}
