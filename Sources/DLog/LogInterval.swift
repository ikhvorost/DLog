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


public struct IntervalStatistics {
    public var count = 0
    public var total: TimeInterval = 0
    public var min: TimeInterval = 0
    public var max: TimeInterval = 0
    public var avg: TimeInterval = 0
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
    
    @objc
    public private(set) var duration: TimeInterval = 0
    
    public var statistics: IntervalStatistics { StatisticsStore.shared[id] }
    
    public override var text: String {
        let statistics = self.statistics
        let items: [(IntervalOptions, String, () -> Any)] = [
            (.duration, "duration", { stringFromTimeInterval(self.duration) }),
            (.count, "count", { statistics.count }),
            (.total, "total", { stringFromTimeInterval(statistics.total) }),
            (.min, "min", { stringFromTimeInterval(statistics.min) }),
            (.max, "max", { stringFromTimeInterval(statistics.max) }),
            (.average, "average", { stringFromTimeInterval(statistics.avg) })
        ]
        let dict = dictionary(from: items, options: config.intervalConfig.options)
        let text = [dict.json(), name].joinedCompact()
        return text
    }
	
    init(logger: DLog, name: String, staticName: StaticString?, category: String, config: LogConfig, scope: LogScope?, metadata: Metadata, file: String, funcName: String, line: UInt) {
        self.logger = logger
        self.name = name
		self.id = "\(file):\(funcName):\(line)".hash
		self.staticName = staticName
        super.init(type: .interval, category: category, config: config, scope: scope, metadata: metadata, file: file, funcName: funcName, line: line, message: nil)
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
		var record = self.statistics
        record.count += 1
        record.total += duration
        if record.min == 0 || record.min > duration {
            record.min = duration
        }
        if record.max == 0 || record.max < duration {
            record.max = duration
        }
        record.avg = record.total / Double(record.count)
        
        StatisticsStore.shared[id] = record
		
        logger.end(interval: self)
	}
}
