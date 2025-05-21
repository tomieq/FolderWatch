//
//  CustomRecognition.swift
//  FolderWatch
//
//  Created by Tomasz KUCHARSKI on 21/05/2025.
//


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
/// xcrun coremlcompiler compile model.mlmodel /model/
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
            self.findObject(in: bytes) { o in
                recognizedObjects = o
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
        let processID = Self.nextProcessID
        let clock = ContinuousClock()
        let duration = clock.measure { [unowned self] in
            let visionHandler = VNImageRequestHandler(data: Data(bytes))
            do {
                
                let visionRequest = VNCoreMLRequest(model: coreModel, completionHandler: { (request, error) in
                    self.logger.i("\(processID): Image processing finished with \(request.results?.count ?? 0) observations")
                    
                    if error != nil {
                        self.logger.e("\(processID): Detection error: \(String(describing: error)).")
                    }
                    
                    guard let detectionRequest = request as? VNCoreMLRequest,
                          let results = detectionRequest.results as? [VNRecognizedObjectObservation] else {
                        callback([])
                        return
                    }
                    callback(results.map{
                        CustomObject(boundingBox: $0.boundingBox,
                                     label: $0.labels.first?.identifier ?? "")
                        
                    })
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
