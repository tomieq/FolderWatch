import Foundation
import FileMonitor
import SwiftGD
import Env
import SwiftExtensions
import Dispatch



enum ConfigError: Swift.Error {
    case invalidPhotoPath
}
let env = Env()
_ = try env.load(filename: "local.env")
guard let photoPath = env.get("PHOTO_DIRECTORY"), let photoDir = URL(string: photoPath) else {
    throw ConfigError.invalidPhotoPath
}

let yoloRecognizer = try CustomRecognition(modelPath: "/Users/tomaskuc/dev/FolderWatch/model/YOLOv3.mlmodelc")

let resultDir = env.get("RESULTS_DIRECTORY")!
_ = try PhotoMonitor(folder: photoDir) { url in
    processImage(url: url)
}
        

//        let result = HumanRecognition.process(bytes: data.bytes, timeLimit: 10)
//        switch result {
//        case .success(let boundingBoxes):
//            
//            for boundingBox in boundingBoxes {
//                let box = pixelConverter.pixels(from: boundingBox).enlarged(scale: 1.6)
//                print("Found car: x: \(box.x), y: \(box.y), width: \(box.width), height: \(box.height)")
//                
//                try image
//                    .cropped(to: Rectangle(x: box.x, y: box.y, width: box.width, height: box.height))?
//                    .export(as: .jpg(quality: 80))
//                    .write(to: URL(fileURLWithPath: "\(resultDir)/result-\(Int.random(in: 1...Int.max)).jpg"))
//            }
//        case .failure(_):
//            break
//            
//        }
        
        
//        let yoloRecognizer = try CustomRecognition(modelPath: "/Users/tomaskuc/dev/FolderWatch/model/YOLOv3.mlmodelc")
//        let carSideRecognizer = try CustomRecognition(modelPath: "/Users/tomaskuc/dev/FolderWatch/model/CarDetector.mlmodelc")
//        let objectResult = yoloRecognizer.process(bytes: data.bytes, timeLimit: 10)
//        switch objectResult {
//        case .success(let objects):
//            for object in objects where object.label == "car" {
//                let box = pixelConverter.pixels(from: object.boundingBox).enlarged(scale: 2.3)
//                print("Found \(object.label): x: \(box.x), y: \(box.y), width: \(box.width), height: \(box.height)")
//                
//                let car = image.cropped(to: Rectangle(x: box.x, y: box.y, width: box.width, height: box.height))!
//                    
//                let pixelConverter = MLCoreToPixelConverter(imageWidth: car.size.width, imageHeight: car.size.height)
//                let result = carSideRecognizer.process(bytes: try car.export(as: .jpg(quality: 80)).bytes, timeLimit: 10)
//                switch result {
//                case .success(let objects):
//                    for object in objects {
//                        let box = pixelConverter.pixels(from: object.boundingBox).enlarged(scale: 1.3)
//                        print("Found \(object.label): x: \(box.x), y: \(box.y), width: \(box.width), height: \(box.height)")
//                        
//                        try car
//                            .cropped(to: Rectangle(x: box.x, y: box.y, width: box.width, height: box.height))?
//                            .export(as: .jpg(quality: 80))
//                            .write(to: URL(fileURLWithPath: "\(resultDir)/\(object.label)-\(Int.random(in: 1...Int.max)).jpg"))
//                    }
//                case .failure(_):
//                    break
//                    
//                }
//            }
//        case .failure:
//            break
//        }
        
        
        


let processes = ProcessManager().getProcessList().first { $0.name.contains("ffmpeg") }
print("ffmpeg running: \(processes.notNil)")
let cameraStream = try CameraStream()
//cameraStream.start()
//
//DispatchQueue.global().asyncAfter(deadline: .now() + 5) {
//    print("Fire!")
//    cameraStream.stop()
//}


func processImage(url: URL) {
    let url = URL(filePath: url.path)
    do {
        let data = try Data(contentsOf: url)
        let image = Image(url: url)!
        let imageSize = ImageSize(width: image.size.width, height: image.size.height)
        let pixelConverter = MLCoreToPixelConverter(imageSize: imageSize)
        
        let objects = try yoloRecognizer.process(bytes: data.bytes, timeLimit: 10).get()
        for (index, object) in objects.enumerated() {
            let box = pixelConverter.pixels(from: object.boundingBox).enlarged(scale: 1.9, imageSize: imageSize)
            
            print("Found \(object.label): x: \(box.x), y: \(box.y), width: \(box.width), height: \(box.height)")
            
            try image
                .cropped(to: Rectangle(x: box.x, y: box.y, width: box.width, height: box.height))?
                .export(as: .jpg(quality: 80))
                .write(to: URL(fileURLWithPath: "\(resultDir)/\(object.label)-\(index)-\(url.lastPathComponent).jpg"))
        }
        try FileManager.default.removeItem(at: url)
    }
    catch {
        print("Error \(error)")
    }
}

RunLoop.main.run()
