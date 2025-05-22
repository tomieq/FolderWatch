//
//  CustomRecognition.swift
//  FolderWatch
//
//  Created by Tomasz KUCHARSKI on 21/05/2025.
//
/// to prepare custom model for use, run:
/// xcrun coremlcompiler compile model.mlmodel /model/

import Foundation
import Vision
import Logger

enum CustomRecognitionError: Error {
    case timeout
}

struct CustomObject {
    let boundingBox: CGRect
    let label: String
}

class CustomRecognition {
    private static var processCounter = 1
    private static var nextProcessID: String {
        defer {
            Self.processCounter += 1
        }
        return String(format: "%06d", Self.processCounter)
    }
    let coreModel: VNCoreMLModel
    private let logger = Logger(CustomRecognition.self)
    
    init(modelPath: String) throws {
        let model = try MLModel(contentsOf: URL(fileURLWithPath: modelPath))
        coreModel = try VNCoreMLModel(for: model)
    }
    
    func process(bytes: [UInt8], timeLimit: Double) -> Result<[CustomObject], HumanRecognitionError> {
        let semaphore = DispatchSemaphore(value: 0)
        var recognizedObjects: [CustomObject] = []
        DispatchQueue.global().async { [unowned self] in
            self.findObject(in: bytes) { object in
                recognizedObjects = object
                semaphore.signal()
            }
        }
        let waitingResult = semaphore.wait(timeout: .now() + timeLimit)
        if case .timedOut = waitingResult {
            logger.i("Image recognition timed out.")
            return .failure(.timeout)
        }
        return .success(recognizedObjects)
    }
    
    private func findObject(in bytes: [UInt8], _ callback: @escaping ([CustomObject]) -> Void) {
        typealias MLRequestType = VNCoreMLRequest
        let processID = Self.nextProcessID
        let clock = ContinuousClock()
        let duration = clock.measure { [unowned self] in
            let visionHandler = VNImageRequestHandler(data: Data(bytes))
            let visionRequest = MLRequestType(model: coreModel, completionHandler: { (request, error) in
                if error.notNil {
                    self.logger.e("\(processID): Image processing finished with error: \(String(describing: error)).")
                } else {
                    self.logger.i("\(processID): Image processing finished with \(request.results?.count ?? 0) observations")
                }
                let results = (request as? MLRequestType)?.results as? [VNRecognizedObjectObservation] ?? []
                callback(results.map {  CustomObject(boundingBox: $0.boundingBox, label: $0.labels.first?.identifier ?? "")})
            })
            logger.i("\(processID): Start image processing")
            do {
                try visionHandler.perform([visionRequest])
            } catch {
                logger.i("\(processID): Error: \(error)")
                callback([])
            }
        }
        self.logger.i("\(processID): Finished within \(duration)")
    }
}
