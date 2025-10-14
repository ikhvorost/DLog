//
//  LogConfig.swift
//
//  Created by Iurii Khvorost <iurii.khvorost@gmail.com> on 2022/02/02.
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

extension OptionSet where RawValue == Int {
  /// All available options
  public static var all: Self {
    Self.init(rawValue: Int.max)
  }
  
  init(_ shift: Int) {
    self.init(rawValue: 1 << shift)
  }
}

/// Indicates which info from the logger should be used.
public struct LogOptions: OptionSet, Sendable {
  /// The corresponding value of the raw type.
  public let rawValue: Int
  
  /// Creates a new option set from the given raw value.
  public init(rawValue: Int) {
    self.rawValue = rawValue
  }
  
  static let message = Self(-1)
  
  /// Start sign
  public static let sign = Self(0)
  
  /// Timestamp
  public static let time = Self(1)
  
  /// Level of the current scope
  public static let level = Self(2)
  
  /// Category
  public static let category = Self(3)
  
  /// The current scope padding
  public static let padding = Self(4)
  
  /// Log type icon
  public static let icon = Self(5)
  
  /// Log type
  public static let type = Self(6)
  
  /// Location
  public static let location = Self(7)
  
  /// Metadata
  public static let metadata = Self(8)
  
  /// Data
  public static let data = Self(9)
  
  /// Compact: `.sign` and `.time`
  public static let compact: Self = [.sign, .time]
  
  /// Regular: `.sign`, `.time`, `.category`, `.padding`, `.type`, `.location`, `.metadata` and `.data`
  public static let regular: Self = [.sign, .time, .category, .padding, .icon, .type, .location, .metadata, .data]
}

/// Style of text to output.
public enum Style: Sendable {
  /// Universal plain text.
  case plain
  
  /// Colored text with ANSI escape codes (useful for Terminal and files).
  case colored
}

/// Contains configuration values regarding to a textual representation
public struct LogConfig: Sendable {
  
  /// Style of text to output.
  public var style: Style = .plain
  
  /// Start sign of the logger
  public var sign: Character = "•"
  
  /// Set which info from the logger should be used. Default value is `LogOptions.regular`.
  public var options: LogOptions = .regular
  
  /// Configuration of the `trace` method
  public var traceConfig = TraceConfig()
  
  /// Configuration of intervals
  public var intervalConfig = IntervalConfig()
  
  /// Creates default configuration.
  public init() {}
}
