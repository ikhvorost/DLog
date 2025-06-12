//
//  OSLog.swift
//
//  Created by Iurii Khvorost <iurii.khvorost@gmail.com> on 2020/08/03.
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
import os
import os.activity


/// A target output that sends log messages to the Unified Logging System.
///
/// It captures telemetry from your app for debugging and performance analysis and then you can use various tools to
/// retrieve log information such as: `Console` and `Instruments` apps, command line tool `"log"` etc.
///
struct OSLog {
  
  private static let types: [LogType : OSLogType] = [
    .log : .default,
    // Debug
    .trace : .debug,
    .debug : .debug,
    // Info
    .info : .info,
    // Error
    .warning : .error,
    .error : .error,
    // Fault
    .assert : .fault,
    .fault : .fault,
  ]
  
  private let subsystem: String
  private let logs = Atomic([String : os.OSLog]())
  
  /// Creates`OSlog` output object.
  ///
  /// To create OSLog you can use subsystem strings that identify major functional areas of your app, and you specify
  /// them in reverse DNS notation—for example, com.your_company.your_subsystem_name.
  ///
  /// 	let logger = DLog(OSLog(subsystem: "com.myapp.logger"))
  ///
  /// - Parameters:
  ///		- subsystem: An identifier string, in reverse DNS notation, that represents the subsystem that’s performing
  ///		logging (defaults to `"com.dlog.logger"`).
  ///		- source: A source output (defaults to `.textPlain`)
  ///
  public init(subsystem: String = "com.dlog.logger") {
    self.subsystem = subsystem
  }
  
  private func oslog(category: String) -> os.OSLog {
    logs.sync {
      if let log = $0[category] {
        return log
      }
      let log = os.OSLog(subsystem: subsystem, category: category)
      $0[category] = log
      return log
    }
  }
}
  
extension OSLog: Output {
  
  public func log(item: LogItem) {
    switch item {
      // Scope
      case let scope as LogScopeItem:
        scope.activity.sync { state in
          if scope.type == .scopeEnter {
            let activity = _os_activity_create(Dynamic.dso, strdup(item.message), Dynamic.OS_ACTIVITY_CURRENT, OS_ACTIVITY_FLAG_DEFAULT)
            os_activity_scope_enter(activity, &state)
          }
          else {
            os_activity_scope_leave(&state)
          }
        }

      // Interval
      case let interval as LogIntervalItem:
        let log = oslog(category: interval.category)
        let id = interval.signpostId.value ?? OSSignpostID(log: log)
        interval.signpostId.value = id
        
        if interval.type == .intervalBegin {
          os_signpost(.begin, log: log, name: interval.name, signpostID: id)
        }
        else {
          os_signpost(.end, log: log, name: interval.name, signpostID: id)
        }
        
      // Item
      default:
        let log = oslog(category: item.category)
        let location = "<\(item.location.fileName):\(item.location.line)>"
        assert(Self.types[item.type] != nil)
        let type = Self.types[item.type]!
        os_log("%{public}@ %{public}@", dso: Dynamic.dso, log: log, type: type, location, item.message)
    }
  }
}
