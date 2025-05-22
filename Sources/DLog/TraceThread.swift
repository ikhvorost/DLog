//
//  TraceThread.swift
//
//  Created by Iurii Khvorost <iurii.khvorost@gmail.com> on 2023/12/14.
//  Copyright © 2023 Iurii Khvorost. All rights reserved.
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

fileprivate extension QualityOfService {
  
  private static let names: [QualityOfService : String] = [
    .userInteractive : "userInteractive",
    .userInitiated: "userInitiated",
    .utility: "utility",
    .background: "background",
    .default :  "default",
  ]
  
  var description: String {
    precondition(Self.names[self] != nil)
    return Self.names[self]!
  }
}

fileprivate extension Thread {
  
  private static let regex = try! NSRegularExpression(pattern: #"\{number = ([0-9]+), name = ([^}]+)\}$"#)
  
  var info: (name: String, number: String) {
    var name = ""
    var number = ""
    let str = description as NSString
    if let match = Self.regex.matches(in: description, options: [], range: NSMakeRange(0, str.length)).first, match.numberOfRanges == 3 {
      number = str.substring(with: match.range(at: 1))
      name = str.substring(with: match.range(at: 2))
      if name == "(null)" {
        name = ""
      }
    }
    return (name, number)
  }
}

/// Indicates which info from threads should be used.
public struct ThreadOptions: OptionSet, Sendable {
  /// The corresponding value of the raw type.
  public let rawValue: Int
  
  /// Creates a new option set from the given raw value.
  public init(rawValue: Int) {
    self.rawValue = rawValue
  }
  
  /// Name
  public static let name = Self(0)
  
  /// Number
  public static let number = Self(1)
  
  /// Priority
  public static let priority = Self(2)
  
  /// QoS
  public static let qos = Self(3)
  
  /// Stack size
  public static let stackSize = Self(4)
  
  /// TID
  public static let tid = Self(5)
  
  /// Compact: `.number` and `.name`
  public static let compact: Self = [.number, .name]
  
  /// Regular: `.number`, `.name` and `.qos`
  public static let regular: Self = [.number, .name, .qos]
}

/// Contains configuration values regarding to thread info.
public struct ThreadConfig: Sendable {
  
  /// Set which info from threads should be used. Default value is `ThreadOptions.compact`.
  public var options: ThreadOptions = .compact
}

func threadMetadata(thread: Thread, tid: UInt64, config: ThreadConfig) -> LogData {
  let items: [(ThreadOptions, String, () -> Any)] = [
    (.name, "name", { thread.info.name }),
    (.number, "number", { thread.info.number }),
    (.priority, "priority", { thread.threadPriority }),
    (.qos, "qos", { "\(thread.qualityOfService.description)" }),
    (.stackSize, "stackSize", { "\(ByteCountFormatter.string(fromByteCount: Int64(thread.stackSize), countStyle: .memory))" }),
    (.tid, "tid", { tid }),
  ]
  return LogData.data(from: items, options: config.options)
}
