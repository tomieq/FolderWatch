import Foundation
import FileMonitor
import SwiftGD
import Env
import Dispatch

let env = Env()
_ = try? env.load(filename: "local.env")
_ = try PhotoMonitor()
dispatchMain()
