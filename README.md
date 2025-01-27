# iPhone Offload Tool

A macOS SwiftUI application to transfer photos and videos from an iPhone (or other cameras) to your Mac using Apple’s [ImageCaptureCore](https://developer.apple.com/documentation/imagecapturecore) framework.

## Features

- **Device Discovery**  
  Automatically detects connected iPhones or cameras via ImageCaptureCore.

- **Flexible Offloads**  
  Choose a destination folder and specify a custom filename prefix (e.g., `IMG_` or `VID_`) for organized file naming. The tool preserves the file extension and can optionally append numeric counters (`0001`, `0002`, etc.).

- **Real-Time Console**  
  A built-in SwiftUI “console” view shows live log messages within the app, handy for debugging or tracking download progress without relying on Xcode’s console.

- **Metadata Awareness**  
  Optionally gathers file size, creation date, and other metadata (subject to camera/iPhone availability) for reference or logging.

## TODO

- **Queue System**  
  Currently, you can select one device/folder at a time to offload. A queue function for managing multiple offload tasks in sequence is on the **to-do list** for upcoming versions.

## Usage

1. **Connect** your iPhone (or camera) to your Mac (ensure you’ve trusted the connection if it’s an iPhone).
2. **Select** the device from the discovered devices list.
3. **Choose** a destination folder.
4. **Specify** a Reel Name.
5. **Download** all items. The app renames and saves them in your chosen folder and create an xml file with some metadatas.


## Contributing

Pull requests or issues are welcome if you’d like to improve the offload process, metadata handling, or help implement the queue system.
