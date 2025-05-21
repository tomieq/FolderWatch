//
//  FaceRecognition.swift
//  FolderWatch
//
//  Created by Tomasz on 21/05/2025.
//

import Foundation
import Vision
import Logger

enum FaceRecognitionError: Error {
    case timeout
}

enum FaceRecognition {
    
    private static var processCounter = 1
    private static var nextProcessID: String {
        defer {
            Self.processCounter += 1
        }
        return String(format: "%06d", Self.processCounter)
    }
    private static let logger = Logger(Self.self)
    
    static func process(bytes: [UInt8], timeLimit: Double) -> Result<[CGRect], FaceRecognitionError> {
        let semaphore = DispatchSemaphore(value: 0)
        var recognizedTexts: [CGRect] = []
        DispatchQueue.global().async {
            Self.findFace(in: bytes) { txts in
                recognizedTexts = txts
                semaphore.signal()
            }
        }
        let waitingResult = semaphore.wait(timeout: .now() + timeLimit)
        if case .timedOut = waitingResult {
            logger.i("Image recognition timed out.")
            return .failure(.timeout)
        }
        return .success(recognizedTexts)
    }
    
    private static func findFace(in bytes: [UInt8], _ callback: @escaping ([CGRect]) -> Void) {
        let processID = self.nextProcessID
        let clock = ContinuousClock()
        let duration = clock.measure {
            let visionHandler = VNImageRequestHandler(data: Data(bytes))
            do {
                let visionRequest = VNDetectFaceRectanglesRequest(completionHandler: { (request, error) in
                    logger.i("\(processID): Image processing finished with \(request.results?.count ?? 0) observations")
                    
                    if error != nil {
                        logger.e("\(processID): FaceDetection error: \(String(describing: error)).")
                    }
                    
                    guard let faceDetectionRequest = request as? VNDetectFaceRectanglesRequest,
                          let results = faceDetectionRequest.results else {
                        callback([])
                        return
                    }
                    callback(results.map{ $0.boundingBox })
                })
                logger.i("\(processID): Start image processing")
                try visionHandler.perform([visionRequest])
            } catch {
                logger.i("\(processID): Error: \(error)")
                callback([])
            }
        }
        print("\(processID): Finished within \(duration)")
    }
}
