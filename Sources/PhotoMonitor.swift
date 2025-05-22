//
//  PhotoMonitor.swift
//  FolderWatch
//
//  Created by Tomasz on 21/05/2025.
//

import Foundation
import FileMonitor
import Logger

struct PhotoMonitor: FileDidChangeDelegate {
    private let watcher: ((URL) -> Void)
    private let logger = Logger(PhotoMonitor.self)

    init(folder: URL, watcher: @escaping (URL) -> Void) throws {
        self.watcher = watcher
        let monitor = try FileMonitor(directory: folder, delegate: self )
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
