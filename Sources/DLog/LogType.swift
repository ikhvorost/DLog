//
//  LogType.swift
//
//  Created by Iurii Khvorost <iurii.khvorost@gmail.com> on 2025/05/14.
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
  
  /// The interval begin log level.
  case intervalBegin
  /// The interval end log level.
  case intervalEnd
  
  /// The scope enter log level.
  case scopeEnter
  /// The scope leave log level.
  case scopeLeave
}

extension LogType: Sendable {
  
  static let icons: [LogType : String] = [
    .log : "💬",
    .trace : "#️⃣",
    .debug : "▶️",
    .info : "✅",
    .warning: "⚠️",
    .error : "⚠️",
    .assert : "🅰️",
    .fault : "🆘",
    .intervalBegin : "🕛",
    .intervalEnd : "🕑",
    .scopeEnter: "⬇️",
    .scopeLeave: "⬆️",
  ]
  
  /// The emoji symbol
  public var icon: String {
    Self.icons[self]!
  }
  
  static let titles: [LogType : String] = [
    .log : "LOG",
    .trace : "TRACE",
    .debug : "DEBUG",
    .info : "INFO",
    .warning : "WARNING",
    .error : "ERROR",
    .assert : "ASSERT",
    .fault : "FAULT",
    .intervalBegin : "INTERVAL",
    .intervalEnd : "INTERVAL",
    .scopeEnter : "SCOPE",
    .scopeLeave : "SCOPE",
  ]
  
  /// The title
  public var title: String {
    Self.titles[self]!
  }
}
