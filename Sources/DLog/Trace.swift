//
//  Trace.swift
//
//  Created by Iurii Khvorost <iurii.khvorost@gmail.com> on 2021/04/15.
//  Copyright © 2021 Iurii Khvorost. All rights reserved.
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

/// Indicates which info from the `trace` method should be used.
public struct TraceOptions: OptionSet {
  /// The corresponding value of the raw type.
  public let rawValue: Int
  
  /// Creates a new option set from the given raw value.
  public init(rawValue: Int) {
    self.rawValue = rawValue
  }
  
  /// Function
  public static let function = Self(0)
  
  /// Process
  public static let process = Self(1)
  
  /// Queue
  public static let queue = Self(2)
  
  /// Stack
  public static let stack = Self(3)
  
  /// Thread
  public static let thread = Self(4)

  /// Compact: `.thread` and `.function`
  public static let compact: Self = [.thread, .function]
  
  /// Regular: `.thread`, `.queue` and `.function`
  public static let regular: Self = [.thread, .queue, .function]
}

/// Trace view style
public enum TraceViewStyle {
  /// Flat view
  case flat
  
  /// Pretty view
  case pretty
}

/// Contains configuration values regarding to the `trace` method.
public struct TraceConfig {
  /// View style
  public var style: TraceViewStyle = .flat
  
  /// Set which info from the `trace` method should be used. Default value is `TraceOptions.compact`.
  public var options: TraceOptions = .compact
  
  /// Configuration of process info
  public var processConfig = ProcessConfig()
  
  /// Configuration of func info
  public var funcConfig = FuncConfig()
  
  /// Configuration of thread info
  public var threadConfig = ThreadConfig()
  
  /// Configuration of stack info
  public var stackConfig = StackConfig()
  
  /// Creates default configuration.
  public init() {}
}

struct TraceInfo {
  let processInfo = ProcessInfo.processInfo
  let queueLabel = String(cString: __dispatch_queue_get_label(nil))
  let stackAddresses = Thread.callStackReturnAddresses.dropFirst(2)
  let thread = Thread.current
  let tid: UInt64 = {
    var value: UInt64 = 0
    pthread_threadid_np(nil, &value)
    return value
  }()
}

func traceMetadata(function: String, traceInfo: TraceInfo, traceConfig: TraceConfig) -> Metadata {
  let items: [(TraceOptions, String, () -> Any)] = [
    (.function, "func", { funcInfo(function: function, config: traceConfig.funcConfig) }),
    (.process, "process", { processMetadata(processInfo: traceInfo.processInfo, config: traceConfig.processConfig) }),
    (.queue, "queue", { traceInfo.queueLabel }),
    (.stack, "stack", { stackMetadata(stackAddresses: traceInfo.stackAddresses, config: traceConfig.stackConfig) }),
    (.thread, "thread", { threadMetadata(thread: traceInfo.thread, tid: traceInfo.tid, config: traceConfig.threadConfig) }),
  ]
  return Metadata.metadata(from: items, options: traceConfig.options)
}
