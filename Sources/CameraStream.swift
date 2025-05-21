//
//  CameraStream.swift
//  FolderWatch
//
//  Created by Tomasz on 21/05/2025.
//
import SwiftExtensions
import Foundation

enum CameraStreamError: Error {
    case missingIP
    case missingPort
    case missingUser
    case missingPassword
    case missingPhotoPath
}

class CameraStream {
    private let processManager = ProcessManager()
    
    private let cameraIP: String
    private let cameraPort: Int
    private let cameraUser: String
    private let cameraPassword: String
    private let photoPath: String

    var ffmpegProcess: RunninngProcess? {
        processManager.getProcessList().first { $0.name.contains("ffmpeg") }
    }

    init() throws {
        cameraIP = try env.get("CAMERA_IP") ?! CameraStreamError.missingIP
        cameraPort = try env.int("CAMERA_PORT") ?! CameraStreamError.missingPort
        cameraUser = try env.get("CAMERA_USER") ?! CameraStreamError.missingUser
        cameraPassword = try env.get("CAMERA_PASSWORD") ?! CameraStreamError.missingPassword
        photoPath = try env.get("PHOTO_DIRECTORY") ?! CameraStreamError.missingPhotoPath
    }
    
    func start() {
        guard ffmpegProcess.isNil else {
            return
        }
        print("Start camera stream")
        DispatchQueue.global().async { [unowned self] in
            Shell().exec("ffmpeg -i rtsp://\(cameraUser):\(cameraPassword)@\(cameraIP):\(cameraPort)/1/h264major -f image2 -vf fps=1 -strftime 1 \(photoPath)/%Y%m%d%H%M%S.jpg &")
        }
    }
    
    func stop() {
        if let processes = ffmpegProcess {
            print("Stop camera stream")
            kill(processes.pid, SIGTERM)
        }
    }
}
