import AppKit
import Foundation
import os.log

/// Shared application logger. Use category strings to filter in Console.app
/// — backend traffic uses `"backend"`, UI uses `"ui"`, store events `"store"`.
enum AppLog {
    static let subsystem = "com.mhdquan.rmbg"

    static let backend = Logger(subsystem: subsystem, category: "backend")
    static let ui = Logger(subsystem: subsystem, category: "ui")
    static let store = Logger(subsystem: subsystem, category: "store")
    static let bootstrap = Logger(subsystem: subsystem, category: "bootstrap")
}
