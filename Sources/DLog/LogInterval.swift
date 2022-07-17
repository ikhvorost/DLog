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
public class LogInterval : LogItem {
	private let id : Int
	@Atomic
    private var begun = false
	
	let name: String
	let staticName: StaticString?
    
    // SignpostID
	@Atomic
    private var _signpostID: Any? = nil
	var signpostID: OSSignpostID? {
		set { _signpostID = newValue }
		get { _signpostID as? OSSignpostID }
	}
    
    // Duration
    @Atomic
    private var _duration: TimeInterval = 0
    @objc
    public var duration: TimeInterval { _duration }
    
    public var statistics: IntervalStatistics { StatisticsStore.shared[id] }
	
	init(params: LogParams, name: String, staticName: StaticString?, file: String, funcName: String, line: UInt) {
		self.id = "\(file):\(funcName):\(line)".hash
		self.name = name
		self.staticName = staticName
		
		super.init(params: params, type: .interval, file: file, funcName: funcName, line: line, message: nil)
        
        message = { [weak self] in
            guard let duration = self?.duration, let statistics = self?.statistics else {
                return ""
            }
			let items: [(IntervalOptions, String, () -> Any)] = [
				(.duration, "duration", { stringFromTimeInterval(duration) }),
                (.count, "count", { statistics.count }),
				(.total, "total", { stringFromTimeInterval(statistics.total) }),
				(.min, "min", { stringFromTimeInterval(statistics.min) }),
				(.max, "max", { stringFromTimeInterval(statistics.max) }),
                (.average, "average", { stringFromTimeInterval(statistics.avg) })
			]
            let dict = dictionary(from: items, options: params.config.intervalConfig.options)
            let text = [dict.json(), name].joinedCompact()
            return LogMessage(stringLiteral: text)
		}
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
        _duration = 0
		
        params.logger.begin(interval: self)
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
        
        _duration = -time.timeIntervalSinceNow
        time = Date()
		
		var record = self.statistics
        record.count += 1
        record.total += _duration
        if record.min == 0 || record.min > _duration {
            record.min = _duration
        }
        if record.max == 0 || record.max < _duration {
            record.max = _duration
        }
        record.avg = record.total / Double(record.count)
        
        StatisticsStore.shared[id] = record
		
        params.logger.end(interval: self)
	}
}
