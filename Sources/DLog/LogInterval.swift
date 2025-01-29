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
public struct IntervalStats {
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

fileprivate class Store {
  static let shared = Store()
  
  private var stats = [Int : IntervalStats]()
  
  subscript(id: Int) -> IntervalStats {
    get {
      stats[id] ?? IntervalStats(count: 0, total: 0, min: 0, max: 0, average: 0)
    }
    set {
      stats[id] = newValue
    }
  }
  
}

/// An object that represents a time interval triggered by the user.
///
/// Interval logs a point of interest in your code as running time statistics for debugging performance.
///
public class LogInterval {
  public class Signpost {
    public var id: OSSignpostID?
  }
  
  public class Item: Log.Item {
    public let signpost: Signpost
    public let name: StaticString
    public let duration: TimeInterval
    public let stats: IntervalStats
    
    init(time: Date, category: String, stack: [Bool]?, type: LogType, location: LogLocation, metadata: Metadata, name: StaticString, config: LogConfig, duration: TimeInterval, stats: IntervalStats, signpost: Signpost) {
      self.signpost = signpost
      self.name = name
      self.duration = duration
      self.stats = stats
      
      super.init(time: time, category: category, stack: stack, type: type, location: location, metadata: metadata, message: "\(name)", config: config)
    }
    
    override func typeText() -> String {
      let text = super.typeText()
      return text.replacingOccurrences(of: "[INTERVAL]", with: "[INTERVAL:\(message)]")
    }
    
    override func data() -> Metadata? {
      let items: [(IntervalOptions, String, Any)] = [
        (.duration, "duration", stringFromTimeInterval(duration)),
        (.count, "count", stats.count),
        (.total, "total", stringFromTimeInterval(stats.total)),
        (.min, "min", stringFromTimeInterval(stats.min)),
        (.max, "max", stringFromTimeInterval(stats.max)),
        (.average, "average", stringFromTimeInterval(stats.average)),
      ]
      return Metadata.metadata(from: items, options: config.intervalConfig.options)
    }
    
    override func messageText() -> String {
      ""
    }
  }
  
  private weak var logger: DLog?
  private let signpost = Signpost()
  
  private let category: String
  private let config: LogConfig
  private let stack: [Bool]?
  private let metadata: Metadata
  private var location: LogLocation
  private let id: Int
  private var start: Date?
  
  public let name: StaticString
  
  /// A time duration
  public private(set) var duration: TimeInterval = 0
  
  /// Accumulated interval statistics
  public var stats: IntervalStats {
    // TODO: use actors
    synchronized(Store.shared) {
      Store.shared[id]
    }
  }
  
  init(logger: DLog, name: StaticString, category: String, config: LogConfig, stack: [Bool]?, metadata: Metadata, location: LogLocation) {
    self.logger = logger
    self.name = name
    self.category = category
    self.config = config
    self.stack = stack
    self.metadata = metadata
    self.location = location
    
    self.id = "\(name):\(location.file):\(location.function):\(location.line)".hash
  }
  
  private func item(type: LogType, stats: IntervalStats) -> Item {
    Item(time: Date(), category: category, stack: stack, type: type, location: location, metadata: metadata, name: name, config: config, duration: duration, stats: stats, signpost: signpost)
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
    synchronized(Store.shared) {
      guard start == nil else {
        return
      }
      
      start = Date()
      duration = 0
      location = LogLocation(fileID: fileID, file: file, function: function, line: line)
      
      let stats = Store.shared[id]
      let item = item(type: .intervalBegin, stats: stats)
      logger?.output?.log(item: item)
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
    synchronized(Store.shared) {
      guard start != nil else {
        return
      }
      duration = -(start?.timeIntervalSinceNow ?? 0)
      location = LogLocation(fileID: fileID, file: file, function: function, line: line)
      
      // Stats
      let stats = Store.shared[id]
      let count = stats.count + 1
      let total = stats.total + duration
      let newStats = IntervalStats(
        count: count,
        total: total,
        min: stats.min == 0 || stats.min > duration ? duration : stats.min,
        max: stats.max == 0 || stats.max < duration ? duration : stats.max,
        average: total / Double(count))
      Store.shared[id] = newStats
      
      let item = item(type: .intervalEnd, stats: newStats)
      logger?.output?.log(item: item)
    }
  }
}
