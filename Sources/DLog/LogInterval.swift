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
  
  /// Creates default configuration.
  public init() {}
}

/// Accumulated interval statistics
public struct IntervalStatistics {
  /// A number of total calls
  public let count: Int
  
  /// A total time duration of all calls
  public let total: TimeInterval
  
  /// A minimum time duration
  public let min: TimeInterval
  
  /// A maximum time duration
  public let max: TimeInterval
  
  /// An average time duration
  public let average: TimeInterval
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
        let data = IntervalStatistics(count: 0, total: 0, min: 0, max: 0, average: 0)
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
  
  init(logger: DLog, name: String, staticName: StaticString?, category: String, config: LogConfig, scope: LogScope?, metadata: Metadata, location: LogLocation) {
    self.logger = logger
    self.name = name
    self.id = "\(location.file):\(location.function):\(location.line)".hash
    self.staticName = staticName
    
    let message = { LogMessage(stringLiteral: name) }
    super.init(message: message, type: .interval, category: category, config: config, scope: scope, metadata: {[metadata]}, location: location)
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
    
    logger.output?.intervalBegin(interval: self)
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
    let stats = self.statistics
    let count = stats.count + 1
    let total = stats.total + duration
    let newStats = IntervalStatistics(
      count: count,
      total: total,
      min: stats.min == 0 || stats.min > duration ? duration : stats.min,
      max: stats.max == 0 || stats.max < duration ? duration : stats.max,
      average: total / Double(count))
    
    StatisticsStore.shared[id] = newStats
    
    // Metadata
    let items: [(IntervalOptions, String, () -> Any)] = [
      (.average, "average", { stringFromTimeInterval(newStats.average) }),
      (.count, "count", { newStats.count }),
      (.duration, "duration", { stringFromTimeInterval(self.duration) }),
      (.max, "max", { stringFromTimeInterval(newStats.max) }),
      (.min, "min", { stringFromTimeInterval(newStats.min) }),
      (.total, "total", { stringFromTimeInterval(newStats.total) }),
    ]
    let metadata = Metadata.metadata(from: items, options: config.intervalConfig.options)
    self.metadata = _metadata() + [metadata]
    
    logger.output?.intervalEnd(interval: self)
  }
}
