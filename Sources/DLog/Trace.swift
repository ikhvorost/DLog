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
  
  /// Process
  public static let process = Self(0)
  
  /// Thread
  public static let thread = Self(1)
  
  /// Queue
  public static let queue = Self(2)
  
  /// Function
  public static let function = Self(3)
  
  /// Stack
  public static let stack = Self(4)

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
}

fileprivate func queueLabel() -> String {
  String(cString: __dispatch_queue_get_label(nil))
}

extension Array where Element == String {
  func joinedCompact() -> String {
    compactMap { $0.isEmpty ? nil : $0 }
      .joined(separator: " ")
  }
}

func dictionary<Option: OptionSet>(from items: [(Option, String, () -> Any)], options: Option) -> [String : Any] {
  let keyValues: [(String, Any)] = items
    .compactMap {
      guard options.contains($0.0 as! Option.Element) else {
        return nil
      }
      let key = $0.1
      let value = $0.2()
      
      if let text = value as? String, text.isEmpty {
        return nil
      }
      else if let dict = value as? [String : Any], dict.isEmpty {
        return nil
      }
      
      return (key, value)
    }
  return Dictionary(uniqueKeysWithValues: keyValues)
}

func traceMetadata(function: String, processInfo: ProcessInfo, thread: Thread, stackAddresses: ArraySlice<NSNumber>, traceConfig: TraceConfig) -> Metadata {
  let items: [(TraceOptions, String, () -> Any)] = [
    (.process, "process", { processMetadata(processInfo: processInfo, config: traceConfig.processConfig) }),
    (.thread, "thread", { threadMetadata(thread: thread, config: traceConfig.threadConfig) }),
    (.queue, "queue", { queueLabel() }),
    (.function, "func", { funcInfo(function: function, config: traceConfig.funcConfig) }),
    (.stack, "stack", { stackMetadata(stackAddresses: stackAddresses, config: traceConfig.stackConfig) }),
  ]
  return dictionary(from: items, options: traceConfig.options)
}
