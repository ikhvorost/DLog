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


public struct TraceInfo {
  public let processInfo = ProcessInfo.processInfo
  public let queueLabel = String(cString: __dispatch_queue_get_label(nil))
  public let stackAddresses = Thread.callStackReturnAddresses.dropFirst(2)
  public let thread = Thread.current
  public let tid: UInt64
  
  init() {
    var value: UInt64 = 0
    pthread_threadid_np(nil, &value)
    tid = value
  }
}

public final class LogTrace: Log.Item, @unchecked Sendable {
  public let traceInfo = TraceInfo()
  
  init(category: String, stack: [Bool]?, location: LogLocation, metadata: Metadata, message: String, config: LogConfig) {
    super.init(category: category, stack: stack, type: .trace, location: location, metadata: metadata, message: message, config: config)
  }
  
  override func data() -> LogData? {
    let items: [(TraceOptions, String, Any)] = [
      (.function, "func", funcInfo(function: location.function, config: config.traceConfig.funcConfig)),
      (.process, "process", processMetadata(processInfo: traceInfo.processInfo, config: config.traceConfig.processConfig)),
      (.queue, "queue", traceInfo.queueLabel),
      (.stack, "stack", stackMetadata(moduleName: location.moduleName, stackAddresses: traceInfo.stackAddresses, config: config.traceConfig.stackConfig)),
      (.thread, "thread", threadMetadata(thread: traceInfo.thread, tid: traceInfo.tid, config: config.traceConfig.threadConfig)),
    ]
    return LogData.data(from: items, options: config.traceConfig.options)
  }
}
