//
//  TraceProcess.swift
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

/// Contains configuration values regarding to a process info.
public struct ProcessOptions: OptionSet {
  
  /// The corresponding value of the raw type.
  public let rawValue: Int
  
  /// Creates a new option set from the given raw value.
  public init(rawValue: Int) {
    self.rawValue = rawValue
  }
  
  /// The identifier of the process.
  public static let pid = Self(0)
  
  /// The name of the process.
  public static let name = Self(1)
  
  /// Global unique identifier for the process.
  public static let guid = Self(2)
    
  /// Compact: `.pid` and `.name`
  public static let compact: Self = [.pid, .name]
}

/// Contains configuration values regarding to a process info.
public struct ProcessConfig {
  
  /// Set which info from the current process should be used. Default value is `ProcessOptions.compact`.
  public var options: ProcessOptions = .compact
}

func process(config: ProcessConfig) -> [String : Any] {
  let process = ProcessInfo()
  
  let items: [(ProcessOptions, String, () -> Any)] = [
    (.pid, "pid", { process.processIdentifier }),
    (.name, "name", { process.processName }),
    (.guid, "guid", { process.globallyUniqueString }),
  ]
  
  let dict = dictionary(from: items, options: config.options)
  return dict
}
