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


fileprivate class IntervalData {
	var count = 0
	var total: TimeInterval = 0
	var min: TimeInterval = 0
	var max: TimeInterval = 0
	var avg: TimeInterval = 0
}

/// An object that represents a time interval triggered by the user.
///
/// Interval logs a point of interest in your code as running time statistics for debugging performance.
///
public class LogInterval : LogItem {
    @Atomic static private var intervals = [Int : IntervalData]()
	
	private static func intervalData(id: Int) -> IntervalData {
		if let data = Self.intervals[id] {
			return data
		}
		
		let data = IntervalData()
		Self.intervals[id] = data
		return data
	}
	
	private let id : Int
	private let logger: DLog
	@Atomic private var begun = false
	
	let name: String
	let staticName: StaticString?
	
	// SignpostID
	private var _signpostID: Any? = nil
	var signpostID: OSSignpostID? {
		set { _signpostID = newValue }
		get { _signpostID as? OSSignpostID }
	}
	
	/// A time duration
    @objc
	private(set) public var duration: TimeInterval = 0
	
	/// A number of total calls
    @objc
	internal(set) public var count = 0
	
	/// A total time duration of all calls
    @objc
	internal(set) public var total: TimeInterval = 0
	
	/// A minimum time duration
    @objc
	internal(set) public var min: TimeInterval = 0
	
	/// A maximum time duration
    @objc
	internal(set) public var max: TimeInterval = 0
	
	/// An average time duration
    @objc
	internal(set) public var avg: TimeInterval = 0
    
    init(logger: DLog, category: String, scope: LogScope?, name: String, staticName: StaticString?, file: String, funcName: String, line: UInt, config: LogConfig) {
		self.id = "\(file):\(funcName):\(line)".hash
		self.logger = logger
        self.name = name
		self.staticName = staticName
		
		super.init(category: category, scope: scope, type: .interval, file: file, funcName: funcName, line: line, message: nil, config: config)
		
		message = {
			let items: [(IntervalOptions, String, () -> String)] = [
				(.duration, "duration", { "\(Text.stringFromTime(interval: self.duration))" }),
				(.count, "count", { "\(self.count)" }),
				(.total, "total", { "\(Text.stringFromTime(interval: self.total))" }),
				(.min, "min", { "\(Text.stringFromTime(interval: self.min))" }),
				(.max, "max", { "\(Text.stringFromTime(interval: self.max))" }),
				(.average, "average", { "\(Text.stringFromTime(interval: self.avg))" })
			]
			let json = jsonDescription(title: self.name, items: items, options: config.intervalConfig.options)
            return LogMessage(stringLiteral: json)
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
		
		synchronized(Self.self as AnyObject) {
			let data = Self.intervalData(id: id)
			
			data.count += 1
			data.total += duration
			if data.min == 0 || data.min > duration {
				data.min = duration
			}
			if data.max == 0 || data.max < duration {
				data.max = duration
			}
			data.avg = data.total / Double(data.count)
			
			count = data.count
			total = data.total
			min = data.min
			max = data.max
			avg = data.avg
		}
		
		logger.end(interval: self)
	}
}
