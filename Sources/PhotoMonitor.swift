//
//  PhotoMonitor.swift
//  FolderWatch
//
//  Created by Tomasz on 21/05/2025.
//

import Foundation
import FileMonitor
import SwiftGD
import Env

enum PhotoMonitorError: Swift.Error {
    case invalidPhotoPath
    case invalidThumbnailPath
}

struct PhotoMonitor: FileDidChangeDelegate {
    let thumbnailWidth = env.int("THUMBNAIL_WIDTH") ?? 200
    let thumbnailDir: URL
    init() throws {
        guard let photoPath = env.get("PHOTO_DIRECTORY"), let photoDir = URL(string: photoPath) else {
            throw PhotoMonitorError.invalidPhotoPath
        }
        guard let thumbPath = env.get("THUMBS_DIRECTORY"), let thumbDir = URL(string: thumbPath) else {
            throw PhotoMonitorError.invalidThumbnailPath
        }
        self.thumbnailDir = thumbDir
        print("thumbnailWidth: \(thumbnailWidth), thumbnailDir: \(thumbnailDir)")
        let monitor = try FileMonitor(directory: photoDir, delegate: self )
        try monitor.start()
    }
    
    public func fileDidChanged(event: FileChange) {
        switch event {
        case .added(let file):
            print("New image \(file.path)")
            if let image = Image(url: file) {
                let thumbnailPath = thumbnailDir.appending(path: file.lastPathComponent)
                print("Store thumbnail to \(thumbnailPath.path)")
                image.resizedTo(width: thumbnailWidth)?.write(to: thumbnailPath)
            }
        default:
            break
        }
    }
}
