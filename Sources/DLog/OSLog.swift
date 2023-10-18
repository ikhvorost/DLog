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
import os.log
import os.activity

/// A target output that sends log messages to the Unified Logging System.
///
/// It captures telemetry from your app for debugging and performance analysis and then you can use various tools to
/// retrieve log information such as: `Console` and `Instruments` apps, command line tool `"log"` etc.
///
public class OSLog : LogOutput {
  
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
  
  private var subsystem: String
  private var logs = [String : os.OSLog]()
  
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
  public init(subsystem: String = "com.dlog.logger", source: LogOutput = .textPlain) {
    self.subsystem = subsystem
    
    super.init(source: source)
  }
  
  private func oslog(category: String) -> os.OSLog {
    synchronized(self) {
      if let log = logs[category] {
        return log
      }
      let log = os.OSLog(subsystem: subsystem, category: category)
      logs[category] = log
      return log
    }
  }
  
  // MARK: - LogOutput
  
  override func log(item: LogItem) -> String? {
    let log = oslog(category: item.category)
    
    let location = "<\(item.fileName):\(item.line)>"
    
    assert(Self.types[item.type] != nil)
    let type = Self.types[item.type]!
    os_log("%{public}@ %{public}@", dso: Dynamic.dso, log: log, type: type, location, item.text)
    
    return super.log(item: item)
  }
  
  override func scopeEnter(scope: LogScope) -> String? {
    if let os_activity_current = Dynamic.OS_ACTIVITY_CURRENT {
      let activity = _os_activity_create(Dynamic.dso, strdup(scope.name), os_activity_current, OS_ACTIVITY_FLAG_DEFAULT)
      os_activity_scope_enter(activity, &scope.os_state)
    }
    return super.scopeEnter(scope: scope)
  }
  
  override func scopeLeave(scope: LogScope) -> String? {
    if Dynamic.OS_ACTIVITY_CURRENT != nil {
      os_activity_scope_leave(&scope.os_state);
    }
    return super.scopeLeave(scope: scope)
  }
  
  override func intervalBegin(interval: LogInterval) {
    super.intervalBegin(interval: interval)
    
    let log = oslog(category: interval.category)
    if interval.signpostID == nil {
      interval.signpostID = OSSignpostID(log: log)
    }
    
    if let name = interval.staticName {
      os_signpost(.begin, log: log, name: name, signpostID: interval.signpostID!)
    }
  }
  
  override func intervalEnd(interval: LogInterval) -> String? {
    let log = oslog(category: interval.category)
    
    if let name = interval.staticName {
      os_signpost(.end, log: log, name: name, signpostID: interval.signpostID!)
    }
    return super.intervalEnd(interval: interval)
  }
}
