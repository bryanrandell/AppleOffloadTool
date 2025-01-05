//
//  DeviceManager.swift
//  AppleOffloadTool
//
//  Created by Bryan RANDELL on 05/01/2025.
//
import SwiftUI
import ImageCaptureCore
import DownloadTask

class DeviceManager: NSObject,
                     ObservableObject,
                     ICDeviceBrowserDelegate,
                     ICCameraDeviceDelegate,
                     ICCameraDeviceDownloadDelegate
{
    func deviceDidBecomeReady(withCompleteContentCatalog device: ICCameraDevice) {
        print("Device is ready with complete content catalog: \(device.mediaFiles?.count ?? 0) items")
    }
    
    // MARK: - Properties
    
    private let deviceBrowser = ICDeviceBrowser()
    
    @Published var discoveredDevices: [ICDevice] = []
    @Published var selectedCamera: ICCameraDevice?
    
    // MARK: - The Download Queue
    @Published var downloadQueue: [DownloadTask] = []

    private var isQueueRunning = false
    
    // MARK: - Init
    override init() {
        super.init()
        
        // 1) Set up device browser
        deviceBrowser.delegate = self
        
        // This mask indicates we want local camera devices:
        deviceBrowser.browsedDeviceTypeMask = ICDeviceTypeMask(
            rawValue: ICDeviceTypeMask.camera.rawValue | ICDeviceLocationTypeMask.local.rawValue
        )!
        
        // 2) Start browsing
        deviceBrowser.start()
        print("Browsing for camera devices...")
    }
    
    // MARK: - Queue Management

    /// Adds a new task to the queue in "pending" state.
    func addTask(device: ICCameraDevice, folderURL: URL, prefix: String) {
        let task = DownloadTask(device: device, folderURL: folderURL, prefix: prefix, status: .pending)
        downloadQueue.append(task)
    }
    
    /// Called when user clicks "Start Queue"
    func startQueue() {
        guard !isQueueRunning else { return }
        isQueueRunning = true
        runNextTask()
    }
    
    /// Moves on to the next pending task. If none, queue stops.
    private func runNextTask() {
        // Find the first pending task
        guard let index = downloadQueue.firstIndex(where: { $0.status == .pending }) else {
            print("No more pending tasks. Queue done!")
            isQueueRunning = false
            return
        }
        
        // Update status to inProgress
        downloadQueue[index].status = .inProgress
        
        // Actually run the download using your existing method
        let task = downloadQueue[index]
        
        // 1) Set the selected camera
        self.selectedCamera = task.device
        
        // 2) Call your existing method (or a new one) to download all items
        //    But we must handle the "finished" event to mark the task .done or .failed
        print("Starting download for device: \(task.device.name ?? "Unknown"), prefix=\(task.prefix)")
        
        // Possibly store an index so the delegate callbacks know which task is active
        activeTaskIndex = index
        
        // Example: We'll create a dedicated method that does the loop of downloading,
        // but we rely on the ICCameraDeviceDownloadDelegate to notify once finished.
        downloadAllItems(filePathURL: task.folderURL, fileNamePrefix: task.prefix)
    }
    
    /// We keep track of which queue item is currently in progress
    private var activeTaskIndex: Int? = nil

    
    // MARK: - Device Selection
    func selectDevice(_ device: ICDevice) {
        guard let camera = device as? ICCameraDevice else { return }
        // Become the camera's delegate
        camera.delegate = self
        // Open a session so we can list media files
        camera.requestOpenSession()
        selectedCamera = camera
        
        print("UUID = \(camera.uuidString ?? "Unknown UUID")")
        print("Serial = \(camera.serialNumberString ?? "Unknown Serial")")
        print("persistentID = \(camera.persistentIDString ?? "Unknown persistentID")")
    
    }
    
    // MARK: - Example Download
    func downloadAllItems(filePathURL: URL, fileNamePrefix: String) {
        guard let camera = selectedCamera else { return }
        
        // 1) Get some ID from the camera.
       //    - Check what's available in your SDK: camera.uuidString? camera.serialNumberString?
       //    - Or just use the camera’s name if you want.
        // If the camera has a UUID, take the first 8 characters.
        // Otherwise, fall back to "UnknownDev".
        let shortID: String
        if let serialString = camera.serialNumberString, !serialString.isEmpty {
            shortID = String(serialString.suffix(4))  // e.g. "9ABCDEF0"
        } else {
            shortID = "UnknownDev"
            }
       // 2) Build the subdirectory name.
       //    For example: "Holiday_ABC12345"
       let subdirectoryName = "\(fileNamePrefix)_\(shortID)"
        
        // 3) Build the subdirectory URL inside the user-chosen filePathURL
        let subdirectoryURL = filePathURL.appendingPathComponent(subdirectoryName)

        // 4) Create the folder if it doesn’t exist
        do {
            try FileManager.default.createDirectory(
                at: subdirectoryURL,
                withIntermediateDirectories: true,
                attributes: nil
            )
            print("Created/Confirmed subdirectory at \(subdirectoryURL.path)")
        } catch {
            print("Failed to create subdirectory: \(error)")
            return
        }
    
        // camera.mediaFiles is [ICCameraItem], but we need ICCameraFile to download
//        for item in camera.mediaFiles ?? [] {
        let items = camera.mediaFiles ?? []
        let fileCount = items.count
        for (index, item) in items.enumerated() {
            guard let file = item as? ICCameraFile else { continue }
            
            print("Downloading file: \(file.name ?? "file") in \(filePathURL.path)")
            let originalName = file.name ?? "file"
            let fileExtension = (originalName as NSString).pathExtension
            
            let imageExtensions = ["jpg", "jpeg", "png", "heic", "heif", "tif", "tiff"]
            let videoExtensions = ["mov", "mp4", "m4v", "avi"]
            
            // Create a unique file name
            // Decide IMG_ or VID_ based on mediaSubType
            
            var typePrefix = "_FILE_"
            if imageExtensions.contains(fileExtension.lowercased()) {
                typePrefix = "_IMG_"
            } else if videoExtensions.contains(fileExtension.lowercased()) {
                typePrefix = "_VID_"
            }
            
            // 3) Build the zero-padded number suffix
            //    For the 1st file, index = 0, so we do (index + 1) to start at 1.
            //    %04d => "0001", "0002", etc.
            let fileNumber = String(format: "%04d", index + 1)

            // 4) Construct final name: e.g. "IMG_2023_0001.jpg"
            //    - typePrefix: "IMG_" or "VID_"
            //    - fileNamePrefix: the user’s own prefix, e.g. "Holiday_" or "2023_"
            //    - fileNumber: "0001"
            //    - extension: the original extension
            let finalName = "\(fileNamePrefix)\(typePrefix)\(fileNumber).\(fileExtension)"

            print("Downloading file: original=\(originalName), newName=\(finalName)")
            
            // Call the new requestDownloadFile using the Swift 5.7+ signature
            camera.requestDownloadFile(
                file,
                options: [
                    ICDownloadOption.downloadsDirectoryURL: subdirectoryURL,
                    ICDownloadOption.saveAsFilename: finalName,
                    ICDownloadOption.overwrite: true
                ],
                downloadDelegate: self,
                didDownloadSelector: #selector(didDownloadFile(_:error:options:contextInfo:)),// no didDownloadSelector needed
                contextInfo: nil
            )
        }
    }
    
//    // Example of a method that sets a default folder (not used yet)
//    func downloadFolderURL() {
//        let folderURL = FileManager.default.homeDirectoryForCurrentUser
//            .appendingPathComponent("Downloads")
//            .appendingPathComponent("Camera Downloads")
//        // do something with `folderURL`
//        print("Sample default folder: \(folderURL.path)")
//    }
    
    // MARK: - ICDeviceBrowserDelegate
    func deviceBrowser(_ browser: ICDeviceBrowser, didAdd device: ICDevice, moreComing: Bool) {
        print("Discovered device: \(device.name ?? "Unnamed")")
        discoveredDevices.append(device)
    }
    func deviceBrowser(_ browser: ICDeviceBrowser, didRemove device: ICDevice, moreGoing: Bool) {
        print("Removed device: \(device.name ?? "Unnamed")")
        discoveredDevices.removeAll { $0 === device }
    }
    
    // MARK: - ICDeviceDelegate / ICCameraDeviceDelegate
    
    // Called when a session is opened
    func device(_ device: ICDevice, didOpenSessionWithError error: (any Error)?) {
        if let nsError = error as? NSError {
            print("didOpenSessionWithError: domain=\(nsError.domain), code=\(nsError.code)")
        } else if let swiftError = error {
            print("didOpenSessionWithError: \(swiftError.localizedDescription)")
        } else {
            print("Session opened successfully for device: \(device.name ?? "Unknown")")
        }
    }
    
    // Called when the session is closed
    func device(_ device: ICDevice, didCloseSessionWithError error: (any Error)?) {
        if let nsError = error as? NSError {
            print("didCloseSessionWithError: domain=\(nsError.domain), code=\(nsError.code)")
        } else if let swiftError = error {
            print("didCloseSessionWithError: \(swiftError.localizedDescription)")
        } else {
            print("Session closed for device: \(device.name ?? "Unknown") with no error.")
        }
    }
    
    // Called when the device is "ready" to list files
    func deviceDidBecomeReady(_ device: ICDevice) {
        print("Device is ready: \(device.name ?? "Unknown")")
    }
    
    // MARK: - ICCameraDeviceDelegate callbacks
    func cameraDevice(_ camera: ICCameraDevice, didAdd items: [ICCameraItem]) {
        for item in items {
            if let file = item as? ICCameraFile {
                print("New file on camera: \(file.name ?? "Unnamed")")
            }
        }
    }
    
    func cameraDevice(_ camera: ICCameraDevice, didRemove items: [ICCameraItem]) {
        for item in items {
            print("Items removed: \(item.name ?? "Unnamed")")
        }
    }
    
    func cameraDevice(_ camera: ICCameraDevice,
                      didReceiveThumbnail thumbnail: CGImage?,
                      for item: ICCameraItem,
                      error: (any Error)?) {
        if let err = error {
            print("Error fetching thumbnail: \(err)")
        } else if thumbnail != nil {
            print("Thumbnail received for item: \(item.name ?? "Unnamed")")
        }
    }
    
    func cameraDevice(_ camera: ICCameraDevice,
                      didReceiveMetadata metadata: [AnyHashable : Any]?,
                      for item: ICCameraItem,
                      error: (any Error)?) {
        if let err = error {
            print("Error receiving metadata: \(err)")
        } else if let data = metadata {
            print("Metadata received for \(item.name ?? "Unnamed"): \(data)")
        }
    }
    
    func cameraDevice(_ camera: ICCameraDevice, didRenameItems items: [ICCameraItem]) {
        for item in items {
            print("Item renamed: \(item.name ?? "Unnamed")")
        }
    }
    
    func cameraDeviceDidChangeCapability(_ camera: ICCameraDevice) {
        print("Camera device capability changed: \(camera.name ?? "Unnamed")")
    }
    
    func cameraDevice(_ camera: ICCameraDevice, didReceivePTPEvent eventData: Data) {
        print("PTP event received with length: \(eventData.count) bytes")
    }
    
    func cameraDeviceDidRemoveAccessRestriction(_ device: ICDevice) {
        print("Access restriction removed for: \(device.name ?? "Unnamed")")
    }
    
    func cameraDeviceDidEnableAccessRestriction(_ device: ICDevice) {
        print("Access restriction enabled for: \(device.name ?? "Unnamed")")
    }
    
    func didRemove(_ device: ICDevice) {
        print("Device removed: \(device.name ?? "Unnamed")")
    }
    
    // ------------------------------------------------------------------
    // MARK: - ICCameraDeviceDownloadDelegate (NEW STYLE)
    // ------------------------------------------------------------------
    /// Called when a file finishes downloading
    func didDownloadFile(
        _ file: ICCameraFile,
        error: (any Error)?,
        options: [String : Any],
        contextInfo: UnsafeMutableRawPointer?
    ) {
        if let actualError = error {
            // Possibly cast to NSError if needed:
            let nsError = actualError as NSError
            print("Failed to download \(file.name ?? "file"): domain=\(nsError.domain), code=\(nsError.code)")
        } else {
            print("Downloaded file: \(file.name ?? "file")")
        }
    }
    
    /// Called periodically to update progress for a file being downloaded
    func didReceiveDownloadProgress(
        for file: ICCameraFile,
        downloadedBytes: off_t,
        maxBytes: off_t
    ) {
        let progress = Double(downloadedBytes) / Double(maxBytes) * 100
        print("Downloading \(file.name ?? "file"): \(Int(progress))%")
    }
}
