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
public struct IntervalOptions: OptionSet, Sendable {
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
public struct IntervalConfig: Sendable {
  
  /// Set which info from the intervals should be used. Default value is `IntervalOptions.compact`.
  public var options: IntervalOptions = .compact
  
  /// Creates default configuration.
  public init() {}
}

/// Accumulated interval statistics
public struct IntervalStats: Sendable {
  
  static let stats = IntervalStats(count: 0, total: 0, min: 0, max: 0, average: 0)
  
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

/// An object that represents a time interval triggered by the user.
///
/// Interval logs a point of interest in your code as running time statistics for debugging performance.
///
public final class LogInterval: Sendable {
  
  private static let store = AtomicDictionary([Int : IntervalStats]())
  
  public final class Item: Log.Item, @unchecked Sendable {
    public let name: StaticString
    public let duration: TimeInterval
    public let stats: IntervalStats
    
    let signpostId: Atomic<OSSignpostID?>
    
    init(time: Date, category: String, stack: [Bool]?, type: LogType, location: LogLocation, metadata: Metadata, name: StaticString, config: LogConfig, duration: TimeInterval, stats: IntervalStats, signpostId: Atomic<OSSignpostID?>) {
      self.signpostId = signpostId
      self.name = name
      self.duration = duration
      self.stats = stats
      
      super.init(time: time, category: category, stack: stack, type: type, location: location, metadata: metadata, message: "\(name)", config: config)
    }
    
    override func typeText() -> String {
      let text = super.typeText()
      return text.replacingOccurrences(of: "[INTERVAL]", with: "[INTERVAL:\(message)]")
    }
    
    override func data() -> LogData? {
      let items: [(IntervalOptions, String, Any)] = [
        (.duration, "duration", stringFromTimeInterval(duration)),
        (.count, "count", stats.count),
        (.total, "total", stringFromTimeInterval(stats.total)),
        (.min, "min", stringFromTimeInterval(stats.min)),
        (.max, "max", stringFromTimeInterval(stats.max)),
        (.average, "average", stringFromTimeInterval(stats.average)),
      ]
      return LogData.data(from: items, options: config.intervalConfig.options)
    }
    
    override func messageText() -> String {
      ""
    }
  }
  
  private let logger: DLog
  private let signpostId = Atomic<OSSignpostID?>(nil)
  
  private let category: String
  private let config: LogConfig
  private let stack: [Bool]?
  private let metadata: Metadata
  private let id: Int
  public let name: StaticString
  
  private let start = Atomic<Date?>(nil)
  
  /// A time duration
  public var duration: TimeInterval {
    _duration.value
  }
  private let _duration = Atomic(0.0)
  
  /// Accumulated interval statistics
  public var stats: IntervalStats {
    Self.store[id] ?? .stats
  }
  
  init(logger: DLog, name: StaticString, category: String, config: LogConfig, stack: [Bool]?, metadata: Metadata, location: LogLocation) {
    self.logger = logger
    self.name = name
    self.category = category
    self.config = config
    self.stack = stack
    self.metadata = metadata
    
    self.id = "\(name):\(location.file):\(location.function):\(location.line)".hash
  }
  
  private func item(type: LogType, location: LogLocation, stats: IntervalStats) -> Item {
    Item(time: Date(), category: category, stack: stack, type: type, location: location, metadata: metadata, name: name, config: config, duration: duration, stats: stats, signpostId: signpostId)
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
  public func begin(fileID: String = #fileID, file: String = #file, function: String = #function, line: UInt = #line) {
    synchronized(self) {
      guard start.value == nil else {
        return
      }
      
      start.value = Date()
      _duration.value = 0
      
      let location = LogLocation(fileID: fileID, file: file, function: function, line: line)
      let stats = Self.store[id] ?? .stats
      let item = item(type: .intervalBegin, location: location, stats: stats)
      logger.output?.log(item: item)
    }
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
  public func end(fileID: String = #fileID, file: String = #file, function: String = #function, line: UInt = #line) {
    synchronized(self) {
      guard start.value != nil else {
        return
      }
      let duration = -(start.value?.timeIntervalSinceNow ?? 0)
      _duration.value = duration
      
      let location = LogLocation(fileID: fileID, file: file, function: function, line: line)
      
      // Stats
      let stats = Self.store[id] ?? .stats
      let count = stats.count + 1
      let total = stats.total + duration
      let newStats = IntervalStats(
        count: count,
        total: total,
        min: stats.min == 0 || stats.min > duration ? duration : stats.min,
        max: stats.max == 0 || stats.max < duration ? duration : stats.max,
        average: total / Double(count))
      Self.store[id] = newStats
      
      let item = item(type: .intervalEnd, location: location, stats: newStats)
      logger.output?.log(item: item)
    }
  }
}
