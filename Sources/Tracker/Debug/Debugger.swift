//
//  Debugger.swift
//  Clickstream
//
//  Created by Anirudh Vyas on 18/03/21.
//  Copyright © 2021 Gojek. All rights reserved.
//

import Foundation


final class Debugger {
    
    private let filename: String
    
    init(fileName: String) throws {
        self.filename = fileName
    }
    
    var logFile: URL? {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        return documentsDirectory.appendingPathComponent("\(filename).log")
    }

    func write(_ events: [Event]) {
        guard let logFile = logFile else {
            return
        }

        var message = ""
        events.forEach {
            message.append($0.guid.appending("\n"))
        }
    
        guard let data = (message).data(using: String.Encoding.utf8) else { return }

        if FileManager.default.fileExists(atPath: logFile.path) {
            if let fileHandle = try? FileHandle(forWritingTo: logFile) {
                fileHandle.seekToEndOfFile()
                fileHandle.write(data)
                fileHandle.closeFile()
            }
        } else {
            try? data.write(to: logFile, options: .atomicWrite)
        }
    }
}
