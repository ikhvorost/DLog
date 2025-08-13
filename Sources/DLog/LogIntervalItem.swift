//
//  LogIntervalItem.swift
//
//  Created by Iurii Khvorost <iurii.khvorost@gmail.com> on 2025/05/14.
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
import os


public final class LogIntervalItem: LogItem, @unchecked Sendable {
  let signpostId: Atomic<OSSignpostID?>
  
  public let name: StaticString
  public let duration: TimeInterval
  public let stats: IntervalStats
  
  init(category: String, stack: [Bool]?, type: LogType, location: LogLocation, metadata: Metadata, name: StaticString, config: LogConfig, duration: TimeInterval, stats: IntervalStats, signpostId: Atomic<OSSignpostID?>) {
    self.signpostId = signpostId
    self.name = name
    self.duration = duration
    self.stats = stats
    
    super.init(category: category, stack: stack, type: type, location: location, metadata: metadata, message: "\(name)", config: config, activity: nil)
  }
  
  override func typeText() -> String {
    let text = super.typeText()
    return text.replacingOccurrences(of: "[INTERVAL]", with: "[INTERVAL:\(message)]")
  }
  
  override func data() -> String? {
    let items: [(IntervalOptions, String, () -> Any)] = [
      (.duration, "duration", { stringFromTimeInterval(self.duration) }),
      (.count, "count", { self.stats.count }),
      (.total, "total", { stringFromTimeInterval(self.stats.total) }),
      (.min, "min", { stringFromTimeInterval(self.stats.min) }),
      (.max, "max", { stringFromTimeInterval(self.stats.max) }),
      (.average, "average", { stringFromTimeInterval(self.stats.average) }),
    ]
    let data = LogData.data(from: items, options: config.intervalConfig.options)
    return data.json()
  }
  
  override func messageText() -> String {
    ""
  }
}
