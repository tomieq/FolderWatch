import Foundation
import FileMonitor
import SwiftGD
import Env
import SwiftExtensions
import Dispatch

let env = Env()
_ = try env.load(filename: "local.env")

let resultDir = env.get("RESULTS_DIRECTORY")!
_ = try PhotoMonitor { url in
    do {
        let data = try Data(contentsOf: URL(filePath: url.path))
        let image = Image(url: url)!
        let pixelConverter = BoundingBoxConverter(imageWidth: image.size.width, imageHeight: image.size.height)

        let result = FaceRecognition.process(bytes: data.bytes, timeLimit: 10)
        switch result {
        case .success(let boundingBoxes):
            
            for boundingBox in boundingBoxes {
                let box = pixelConverter.pixels(from: boundingBox).enlarged(scale: 1.3)
                print("Found face: x: \(box.x), y: \(box.y), width: \(box.width), height: \(box.height)")
                
                try image
                    .cropped(to: Rectangle(x: box.x, y: box.y, width: box.width, height: box.height))?
                    .export(as: .jpg(quality: 80))
                    .write(to: URL(fileURLWithPath: "\(resultDir)/result-\(Int.random(in: 1...Int.max)).jpg"))
            }
        case .failure(_):
            break
            
        }
    }
    catch {
        print("Error \(error)")
    }
}
let processes = ProcessManager().getProcessList().first { $0.name.contains("ffmpeg") }
print("ffmpeg running: \(processes.notNil)")
let cameraStream = try CameraStream()
//cameraStream.start()
//
//DispatchQueue.global().asyncAfter(deadline: .now() + 5) {
//    print("Fire!")
//    cameraStream.stop()
//}

RunLoop.main.run()
