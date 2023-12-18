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


/// Logging levels supported by the logger.
///
/// A log type controls the conditions under which a message should be logged.
///
@objc
public enum LogType : Int {
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
  public let scope: LogScope?
  
  /// The log level of this log message.
  public let type: LogType
  
  /// The file name this log message originates from.
  public let fileName: String
  
  /// The function name this log message originates from.
  public let funcName: String
  
  /// The line number of code this log message originates from.
  public let line: UInt
  
  private let _message: () -> LogMessage
  /// Text of this log message.
  public lazy var message: String = { _message().text }()
  
  let config: LogConfig
  
  private let _metadata: () -> [Metadata]
  /// Metadata of log message
  public lazy var metadata: [Metadata] = { _metadata() }()
  
  init(type: LogType, category: String, config: LogConfig, scope: LogScope?, metadata: @escaping () -> [Metadata], file: String, funcName: String, line: UInt, message: @escaping () -> LogMessage) {
    self.type = type
    self.category = category
    self.config = config
    self.scope = scope
    self._metadata = metadata
    self.fileName = (file as NSString).lastPathComponent
    self.funcName = funcName
    self.line = line
    self._message = message
  }
}
