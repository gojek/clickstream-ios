//
//  FileManager.swift
//  Clickstream
//
//  Created by Rishav Gupta on 28/10/22.
//  Copyright © 2022 Gojek. All rights reserved.
//

import Foundation

struct AckEventDetails {
    var guid: String
    var status: String
}

class FileManagerOverride {
    private static var csvString = "\("BatchId"),\("LogType"),\("Timestamp")\n"
    private static var logFile: URL? {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        let fileName = "ios_ete_report_detailed.csv"
        return documentsDirectory.appendingPathComponent(fileName)
    }
    
    static func writeToFile() {
        #if EVENT_VISUALIZER_ENABLED
        let rowLine = "\(Clickstream.ackEvent?.guid ?? "GUID not captured") ,\(Clickstream.ackEvent?.status ?? "Status not captured") ,\(Date())\n"
        csvString = csvString.appending(rowLine)
        
        guard let logFile = logFile else {
            return
        }
        guard let data = rowLine.data(using: String.Encoding.utf8) else { return }
        
        if FileManager.default.fileExists(atPath: logFile.path) {
            if let fileHandle = try? FileHandle(forWritingTo: logFile) {
                fileHandle.seekToEndOfFile()
                fileHandle.write(data)
                fileHandle.closeFile()
            }
        } else {
            do {
                try csvString.write(to: logFile, atomically: true, encoding: String.Encoding.utf8)
            } catch {
                print("Failed to create file")
                print("\(error)")
            }
            print(logFile)
        }
        #endif
    }
}
