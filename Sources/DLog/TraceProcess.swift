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
  
  /// CPU usage (%).
  public static let cpu = Self(0)
  
  /// Global unique identifier for the process.
  public static let guid = Self(1)
  
  /// Memory usage (MB).
  public static let memory = Self(2)
  
  /// The name of the process.
  public static let name = Self(3)
  
  /// The identifier of the process.
  public static let pid = Self(4)
  
  /// Threads count.
  public static let threads = Self(5)
  
  /// Wakeups per second (WPS).
  public static let wps = Self(6)
    
  /// Compact: `.cpu`, `.memory`, `.pid` and `.threads`
  public static let compact: Self = [.cpu, .memory, .pid, .threads]
}

/// Contains configuration values regarding to a process info.
public struct ProcessConfig {
  
  /// Set which info from the current process should be used. Default value is `ProcessOptions.compact`.
  public var options: ProcessOptions = .compact
}

fileprivate class Power {
  
  static let shared = Power()
  
  private var timer: Timer?
  
  private(set) var wakeupsTotalCount: UInt64 = 0
  private(set) var wakeupsPerSecond: UInt64 = 0
  
  // mWh
  private(set) var energyTotal = 0.0
  private(set) var energyPerSecond = 0.0
  
  private init() {
    timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
      let wakeups = TaskInfo.power.task_interrupt_wakeups
      self.wakeupsPerSecond = wakeups - self.wakeupsTotalCount
      self.wakeupsTotalCount = wakeups
      
      // nJ / 3600 = nWh
      let mWh = Double(TaskInfo.power_v2.task_energy) / (3600 * 1000000)
      self.energyPerSecond = mWh - self.energyTotal
      self.energyTotal = mWh
    }
    timer?.fire()
  }
}

func processMetadata(processInfo: ProcessInfo, config: ProcessConfig) -> Metadata {
  let items: [(ProcessOptions, String, () -> Any)] = [
    (.cpu, "cpu", { "\(threadsInfo().cpuUsage)%" }),
    (.guid, "guid", { processInfo.globallyUniqueString }),
    (.memory, "memory", { "\(TaskInfo.vm.phys_footprint / (1024 * 1024))MB"}),
    (.name, "name", { processInfo.processName }),
    (.pid, "pid", { processInfo.processIdentifier }),
    (.threads, "threads", { threadsInfo().threadsCount }),
    (.wps, "wps", { Power.shared.wakeupsPerSecond }),
  ]
  return Metadata.metadata(from: items, options: config.options)
}
