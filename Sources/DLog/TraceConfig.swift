//
//  TraceConfig.swift
//
//  Created by Iurii Khvorost <iurii.khvorost@gmail.com> on 2023/11/17.
//  Copyright © 2022 Iurii Khvorost. All rights reserved.
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

/// Contains configuration values regarding to func info.
public struct FuncConfig {
  
  // Params of a function
  public var params = false
}

/// Indicates which info from threads should be used.
public struct ThreadOptions: OptionSet {
  /// The corresponding value of the raw type.
  public let rawValue: Int
  
  /// Creates a new option set from the given raw value.
  public init(rawValue: Int) {
    self.rawValue = rawValue
  }
  
  /// Number
  public static let number = Self(0)
  
  /// Name (if it exists)
  public static let name = Self(1)
  
  /// Priority
  public static let priority = Self(2)
  
  /// QoS
  public static let qos = Self(3)
  
  /// Stack size
  public static let stackSize = Self(4)
  
  /// Compact: `.number` and `.name`
  public static let compact: Self = [.number, .name]
  
  /// Regular: `.number`, `.name` and `.qos`
  public static let regular: Self = [.number, .name, .qos]
}

/// Contains configuration values regarding to thread info.
public struct ThreadConfig {
  
  /// Set which info from threads should be used. Default value is `ThreadOptions.compact`.
  public var options: ThreadOptions = .compact
}

/// Indicates which info from stacks should be used.
public struct StackOptions: OptionSet {
  /// The corresponding value of the raw type.
  public let rawValue: Int
  
  /// Creates a new option set from the given raw value.
  public init(rawValue: Int) {
    self.rawValue = rawValue
  }
  
  /// Module name
  public static let module = Self(0)
  
  /// Address
  public static let address = Self(1)
  
  /// Stack symbols
  public static let symbols = Self(2)
  
  /// Offset
  public static let offset = Self(3)
  
  /// Frame
  public static let frame = Self(4)
}

/// Contains configuration values regarding to stack info
public struct StackConfig {
  /// Set which info from stacks should be used. Default value is `StackOptions.symbols`.
  public var options: StackOptions = .symbols
  
  /// Depth of stack
  public var depth = 0
}

/// Indicates which info from the `trace` method should be used.
public struct TraceOptions: OptionSet {
  /// The corresponding value of the raw type.
  public let rawValue: Int
  
  /// Creates a new option set from the given raw value.
  public init(rawValue: Int) {
    self.rawValue = rawValue
  }
  
  /// Thread
  public static let thread = Self(0)
  
  /// Queue
  public static let queue = Self(1)
  
  /// Function
  public static let function = Self(2)
  
  /// Stack
  public static let stack = Self(3)
  
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
  
  /// Configuration of func info
  public var funcConfig = FuncConfig()
  
  /// Configuration of thread info
  public var threadConfig = ThreadConfig()
  
  /// Configuration of stack info
  public var stackConfig = StackConfig()
}
