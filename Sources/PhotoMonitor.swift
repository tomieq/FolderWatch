//
//  PhotoMonitor.swift
//  FolderWatch
//
//  Created by Tomasz on 21/05/2025.
//

import Foundation
import FileMonitor
import SwiftGD
import Logger
import Env

enum PhotoMonitorError: Swift.Error {
    case invalidPhotoPath
}
struct PhotoMonitor: FileDidChangeDelegate {
    private let watcher: ((URL) -> Void)
    private let logger = Logger(PhotoMonitor.self)

    init(watcher: @escaping (URL) -> Void) throws {
        guard let photoPath = env.get("PHOTO_DIRECTORY"), let photoDir = URL(string: photoPath) else {
            throw PhotoMonitorError.invalidPhotoPath
        }
        self.watcher = watcher
        let monitor = try FileMonitor(directory: photoDir, delegate: self )
        try monitor.start()
    }
    
    public func fileDidChanged(event: FileChange) {
        switch event {
        case .added(let file):
            logger.i("New image \(file.path)")
            watcher(file)
        default:
            break
        }
    }
}
