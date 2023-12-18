//
//  LogInterval.swift
//
//  Created by Iurii Khvorost <iurii.khvorost@gmail.com> on 2021/05/13.
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
import os.log

/// Indicates which info from intervals should be used.
public struct IntervalOptions: OptionSet {
  /// The corresponding value of the raw type.
  public let rawValue: Int
  
  /// Creates a new option set from the given raw value.
  public init(rawValue: Int) {
    self.rawValue = rawValue
  }
  
  /// Average time duration
  public static let average = Self(0)
  
  /// Number of total calls
  public static let count = Self(1)
  
  /// Time duration
  public static let duration = Self(2)
  
  /// Maximum time duration
  public static let max = Self(3)
  
  /// Minimum time duration
  public static let min = Self(4)
  
  /// Total time duration of all calls
  public static let total = Self(5)
  
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

/// Accumulated interval statistics
public struct IntervalStatistics {
  /// A number of total calls
  public var count = 0
  
  /// A total time duration of all calls
  public var total: TimeInterval = 0
  
  /// A minimum time duration
  public var min: TimeInterval = 0
  
  /// A maximum time duration
  public var max: TimeInterval = 0
  
  /// An average time duration
  public var average: TimeInterval = 0
}

fileprivate class StatisticsStore {
  static let shared = StatisticsStore()
  
  private var intervals = [Int : IntervalStatistics]()
  
  subscript(id: Int) -> IntervalStatistics {
    get {
      synchronized(self) {
        if let data = intervals[id] {
          return data
        }
        let data = IntervalStatistics()
        intervals[id] = data
        return data
      }
    }
    
    set {
      synchronized(self) {
        intervals[id] = newValue
      }
    }
  }
}

/// An object that represents a time interval triggered by the user.
///
/// Interval logs a point of interest in your code as running time statistics for debugging performance.
///
public class LogInterval: LogItem {
  private let logger: DLog
  private let id: Int
  private let name: String
  private let _metadata: Metadata
  @Atomic
  private var begun = false
  
  let staticName: StaticString?
  
  // SignpostID
  @Atomic
  private var _signpostID: Any? = nil
  var signpostID: OSSignpostID? {
    set { _signpostID = newValue }
    get { _signpostID as? OSSignpostID }
  }
  
  /// A time duration
  @objc
  public private(set) var duration: TimeInterval = 0
  
  /// Accumulated interval statistics
  public var statistics: IntervalStatistics { StatisticsStore.shared[id] }
  
  init(logger: DLog, name: String, staticName: StaticString?, category: String, config: LogConfig, scope: LogScope?, metadata: Metadata, file: String, funcName: String, line: UInt) {
    self.logger = logger
    self.name = name
    self.id = "\(file):\(funcName):\(line)".hash
    self.staticName = staticName
    self._metadata = metadata
    
    let message = { LogMessage(stringLiteral: name) }
    super.init(type: .interval, category: category, config: config, scope: scope, metadata: {[metadata]}, file: file, funcName: funcName, line: line, message: message)
  }
  
  /// Start a time interval.
  ///
  /// A time interval can be created and then used for logging running time statistics.
  ///
  /// 	let logger = DLog()
  /// 	let interval = logger.interval("Sort")
  /// 	interval.begin()
  /// 	...
  /// 	interval.end()
  ///
  @objc
  public func begin() {
    guard !begun else { return }
    begun.toggle()
    
    time = Date()
    duration = 0
    
    logger.begin(interval: self)
  }
  
  /// Finish a time interval.
  ///
  /// A time interval can be created and then used for logging running time statistics.
  ///
  /// 	let logger = DLog()
  /// 	let interval = logger.interval("Sort")
  /// 	interval.begin()
  /// 	...
  /// 	interval.end()
  ///
  @objc
  public func end() {
    guard begun else { return }
    begun.toggle()
    
    duration = -time.timeIntervalSinceNow
    time = Date()
    
    // Statistics
    var statistics = self.statistics
    statistics.count += 1
    statistics.total += duration
    if statistics.min == 0 || statistics.min > duration {
      statistics.min = duration
    }
    if statistics.max == 0 || statistics.max < duration {
      statistics.max = duration
    }
    statistics.average = statistics.total / Double(statistics.count)
    
    StatisticsStore.shared[id] = statistics
    
    // Metadata
    let items: [(IntervalOptions, String, () -> Any)] = [
      (.average, "average", { stringFromTimeInterval(statistics.average) }),
      (.count, "count", { statistics.count }),
      (.duration, "duration", { stringFromTimeInterval(self.duration) }),
      (.max, "max", { stringFromTimeInterval(statistics.max) }),
      (.min, "min", { stringFromTimeInterval(statistics.min) }),
      (.total, "total", { stringFromTimeInterval(statistics.total) }),
    ]
    metadata = [_metadata, Metadata.metadata(from: items, options: config.intervalConfig.options)]
    
    logger.end(interval: self)
  }
}
