import Foundation
import FileMonitor
import SwiftGD
import Env
import SwiftExtensions
import Dispatch

let env = Env()
_ = try? env.load(filename: "local.env")
_ = try PhotoMonitor()
let processes = ProcessManager().getProcessList().first { $0.name.contains("ffmpeg") }
print("ffmpeg running: \(processes.notNil)")
let cameraStream = try CameraStream()
cameraStream.start()

DispatchQueue.global().asyncAfter(deadline: .now() + 5) {
    print("Fire!")
    cameraStream.stop()
}

RunLoop.main.run()
