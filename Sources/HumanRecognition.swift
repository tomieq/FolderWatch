//
//  HumanRecognition.swift
//  FolderWatch
//
//  Created by Tomasz on 21/05/2025.
//

import Foundation
import Vision
import Logger

enum HumanRecognitionError: Error {
    case timeout
}

enum HumanRecognition {
    private static var processCounter = 1
    private static var nextProcessID: String {
        defer {
            Self.processCounter += 1
        }
        return String(format: "%06d", Self.processCounter)
    }
    private static let logger = Logger(Self.self)
    
    static func process(bytes: [UInt8], timeLimit: Double) -> Result<[CGRect], HumanRecognitionError> {
        let semaphore = DispatchSemaphore(value: 0)
        var recognizedPeople: [CGRect] = []
        DispatchQueue.global().async {
            Self.findPerson(in: bytes) { txts in
                recognizedPeople = txts
                semaphore.signal()
            }
        }
        let waitingResult = semaphore.wait(timeout: .now() + timeLimit)
        if case .timedOut = waitingResult {
            logger.i("Image recognition timed out.")
            return .failure(.timeout)
        }
        return .success(recognizedPeople)
    }
    
    private static func findPerson(in bytes: [UInt8], _ callback: @escaping ([CGRect]) -> Void) {
        let processID = self.nextProcessID
        let clock = ContinuousClock()
        let duration = clock.measure {
            let visionHandler = VNImageRequestHandler(data: Data(bytes))
            do {
                let visionRequest = VNDetectHumanRectanglesRequest(completionHandler: { (request, error) in
                    logger.i("\(processID): Image processing finished with \(request.results?.count ?? 0) observations")
                    
                    if error != nil {
                        logger.e("\(processID): Detection error: \(String(describing: error)).")
                    }
                    
                    guard let humanDetectionRequest = request as? VNDetectHumanRectanglesRequest,
                          let results = humanDetectionRequest.results else {
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
