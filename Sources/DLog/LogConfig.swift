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

// MARK: - TraceConfig

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
}

/// View style of stack info
public enum StackViewStyle {
    /// Flat view
    case flat
    
    /// Column view
    case column
}

/// Contains configuration values regarding to stack info
public struct StackConfig {
    /// Set which info from stacks should be used. Default value is `StackOptions.symbols`.
    public var options: StackOptions = .symbols
    
    /// Depth of stack
    public var depth = 0
    
    /// View style of stack
    public var style: StackViewStyle = .flat
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

/// Contains configuration values regarding to the `trace` method.
public struct TraceConfig {
    /// Set which info from the `trace` method should be used. Default value is `TraceOptions.compact`.
    public var options: TraceOptions = .compact
    
    /// Configuration of thread info
    public var threadConfig = ThreadConfig()
    
    /// Configuration of stack info
    public var stackConfig = StackConfig()
}

// MARK: - IntervalConfig

/// Indicates which info from intervals should be used.
public struct IntervalOptions: OptionSet {
    /// The corresponding value of the raw type.
    public let rawValue: Int
    
    /// Creates a new option set from the given raw value.
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    /// Time duration
    public static let duration = Self(0)
    
    /// Number of total calls
    public static let count = Self(1)
    
    /// Total time duration of all calls
    public static let total = Self(2)
    
    /// Minimum time duration
    public static let min = Self(3)
    
    /// Maximum time duration
    public static let max = Self(4)
    
    /// Average time duration∂ß
    public static let average = Self(5)
    
    /// Compact: `.duration` and `.average`
    public static let compact: Self = [.duration, .average]
    
    /// Regular: `.duration`, `.average`, `.count` and `.total`
    public static let regular: Self = [.duration, .average, .count, .total]
}

/// Contains configuration values regarding to intervals.
public struct IntervalConfig {
    
    /// Set which info from the intervals should be used. Default value is `IntervalOptions.compact`.
    public var options: IntervalOptions = .compact
}

// MARK: - LogConfig

/// Indicates which info from the logger should be used.
public struct LogOptions: OptionSet {
    /// The corresponding value of the raw type.
    public let rawValue: Int
    
    /// Creates a new option set from the given raw value.
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
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
    
    /// Log type
    public static let type = Self(5)
    
    /// Location
    public static let location = Self(6)
    
    /// Compact: `.sign` and `.time`
    public static let compact: Self = [.sign, .time]
    
    /// Regular: `.sign`, `.time`, `.category`, `.padding`, `.type` and `.location`
    public static let regular: Self = [.sign, .time, .category, .padding, .type, .location]
}

/// Contains configuration values regarding to the logger
public struct LogConfig {
    /// Start sign of the logger
    public var sign: Character = "•"
    
    /// Set which info from the logger should be used. Default value is `LogOptions.regular`.
    public var options: LogOptions = .regular
    
    /// Configuration of the `trace` method
    public var traceConfig = TraceConfig()
    
    /// Configuration of intervals
    public var intervalConfig = IntervalConfig()
    
    /// Creates the logger's default configuration.
    public init() {}
}
