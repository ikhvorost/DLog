//
//  LogItem.swift
//
//  Created by Iurii Khvorost <iurii.khvorost@gmail.com> on 2020/10/14.
//  Copyright © 2020 Iurii Khvorost. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation


/// The location of a log message.
@objcMembers
public class LogLocation: NSObject {
  /// The file ID.
  public let fileID: String
  
  /// The file path.
  public let file: String
  
  /// The function name.
  public let function: String
  
  /// The line number.
  public let line: UInt
  
  /// The module name.
  public lazy var moduleName: String = {
    (fileID as NSString).pathComponents.first!
  }()
  
  /// The file name.
  public lazy var fileName: String = {
    (file as NSString).lastPathComponent
  }()
  
  public init(_ fileID: String, _ file: String, _ function: String, _ line: UInt) {
    self.fileID = fileID
    self.file = file
    self.function = function
    self.line = line
  }
}

/// Logging levels supported by the logger.
///
/// A log type controls the conditions under which a message should be logged.
///
@objc
public enum LogType: Int {
  /// The default log level to capture non critical information.
  case log
  
  /// The informational log level to capture information messages and helpful data.
  case info
  
  /// The trace log level to capture the current function name to help in debugging problems during the development.
  case trace
  
  /// The debug log level to capture information that may be useful during development or while troubleshooting a specific problem.
  case debug
  
  /// The warning log level to capture information about things that might result in an error.
  case warning
  
  /// The error log level to report errors.
  case error
  
  /// The assert log level for sanity checks.
  case assert
  
  /// The fault log level to capture system-level or multi-process information when reporting system errors.
  case fault
  
  /// The interval log level.
  case interval
  
  case scopeEnter
  case scopeLeave
}

/// A base log message class that the logger adds to the logs.
///
/// It contains all available properties of the log message.
///
@objcMembers
public class LogItem: NSObject {
  /// The timestamp of this log message.
  public internal(set) var time = Date()
  
  /// The category of this log message.
  public let category: String
  
  /// The scope of this log message.
  public let stack: [Bool]?
  
  /// The log level of this log message.
  public let type: LogType
  
  /// The location of a log message.
  public let location: LogLocation
  
  /// Text of this log message.
  public let message: String
  
  let config: LogConfig
  
  let _metadata: () -> [Metadata]
  /// Metadata of log message
  public internal(set) lazy var metadata: [Metadata] = { _metadata() }()
  
  init(message: String, type: LogType, category: String, config: LogConfig, stack: [Bool]?, metadata: @escaping () -> [Metadata], location: LogLocation) {
    self.message = message
    self.type = type
    self.category = category
    self.config = config
    self.stack = stack
    self._metadata = metadata
    self.location = location
  }
}


