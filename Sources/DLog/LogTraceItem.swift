//
//  LogTrace.swift
//
//  Created by Iurii Khvorost <iurii.khvorost@gmail.com> on 2025/01/30.
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


/// Represents a collection of information about the current process and stack.
public struct TraceInfo {
  /// Shared process information agent for the process.
  public let processInfo = ProcessInfo.processInfo
  /// The label of the queue.
  public let queueLabel = String(cString: __dispatch_queue_get_label(nil))
  /// The array containing the call stack return addresses.
  public let stackAddresses: ArraySlice<NSNumber>
  /// A thread object representing the current thread of execution.
  public let thread = Thread.current
  /// The thread id.
  public let tid: UInt64
  
  init(stackAddresses: ArraySlice<NSNumber>) {
    self.stackAddresses = stackAddresses
    
    var value: UInt64 = 0
    pthread_threadid_np(nil, &value)
    tid = value
  }
}

/// Represents a trace logging object passed to the outputs.
public final class LogTraceItem: LogItem, @unchecked Sendable {
  
  /// The process and stack information.
  public let traceInfo: TraceInfo
  
  init(category: String, stack: [Bool]?, location: LogLocation, metadata: Metadata, message: String, config: LogConfig, activity: os_activity_t?, stackAddresses: ArraySlice<NSNumber>) {
    self.traceInfo = TraceInfo(stackAddresses: stackAddresses)
    super.init(category: category, stack: stack, type: .trace, location: location, metadata: metadata, message: message, config: config, activity: activity)
  }
  
  override func data() -> String? {
    let items: [(TraceOptions, String, () -> Any)] = [
      (.function, "func", { funcInfo(function: "\(self.location.function)", config: self.config.traceConfig.funcConfig) }),
      (.process, "process", { processMetadata(processInfo: self.traceInfo.processInfo, config: self.config.traceConfig.processConfig) }),
      (.queue, "queue", { self.traceInfo.queueLabel }),
      (.stack, "stack", { stackMetadata(moduleName: self.location.moduleName, stackAddresses: self.traceInfo.stackAddresses, config: self.config.traceConfig.stackConfig) }),
      (.thread, "thread", { threadMetadata(thread: self.traceInfo.thread, tid: self.traceInfo.tid, config: self.config.traceConfig.threadConfig) }),
    ]
    let data = LogData.data(from: items, options: config.traceConfig.options)
    let pretty = self.config.traceConfig.style == .pretty
    return data.json(pretty: pretty)
  }
}
