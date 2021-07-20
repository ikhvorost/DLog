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

/// Indicates which info from `LogInterval` should be used.
public struct IntervalOptions: OptionSet {
	/// The corresponding value of the raw type.
	public let rawValue: UInt8
	
	/// Creates a new option set from the given raw value.
	public init(rawValue: UInt8) {
		self.rawValue = rawValue
	}
	
	private init(_ shift: UInt8) {
		self.rawValue = 1 << shift
	}
	
	/// A time duration should be used
	public static let duration = Self(0)
	
	/// A number of total calls should be used
	public static let count = Self(1)
	
	/// A total time duration of all calls should be used
	public static let total = Self(2)
	
	/// A minimum time duration should be used
	public static let min = Self(3)
	
	/// A maximum time duration should be used
	public static let max = Self(4)
	
	/// An average time duration should be used
	public static let average = Self(5)
	
	/// `duration` and `average` should be used
	public static let compact: Self = [.duration, .average]
	
	/// `duration`, `average`, `count` and `total` should be used
	public static let regular: Self = [.duration, .average, .count, .total]
	
	/// All properties should be used
	public static let all = Self(rawValue: 255)
}

/// Contains configuration values regarding to `LogInterval`.
public struct IntervalConfiguration {
	
	/// Set which info from `LogInteral` should be used. Default value is `IntervalOptions.compact`.
	public var options: IntervalOptions = .compact
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
	
	let name: StaticString
	
	// SignpostID
	private var _signpostID: Any? = nil
	var signpostID: OSSignpostID? {
		set { _signpostID = newValue }
		get { _signpostID as? OSSignpostID }
	}
	
	/// A time duration
	private(set) public var duration: TimeInterval = 0
	
	/// A number of total calls
	internal(set) public var count = 0
	
	/// A total time duration of all calls
	internal(set) public var total: TimeInterval = 0
	
	/// A minimum time duration
	internal(set) public var min: TimeInterval = 0
	
	/// A maximum time duration
	internal(set) public var max: TimeInterval = 0
	
	/// An average time duration
	internal(set) public var avg: TimeInterval = 0
	
	init(logger: DLog, category: String, scope: LogScope?, file: String, funcName: String, line: UInt, name: StaticString, config: LogConfig) {
		self.id = "\(file):\(funcName):\(line)".hash
		self.logger = logger
		self.name = name
		
		super.init(category: category, scope: scope, type: .interval, file: file, funcName: funcName, line: line, text: nil, config: config)
		
		text = {
			let items: [(IntervalOptions, String, () -> String)] = [
				(.duration, "duration", { "\(Text.stringFromTime(interval: self.duration))" }),
				(.count, "count", { "\(self.count)" }),
				(.total, "total", { "\(Text.stringFromTime(interval: self.total))" }),
				(.min, "min", { "\(Text.stringFromTime(interval: self.min))" }),
				(.max, "max", { "\(Text.stringFromTime(interval: self.max))" }),
				(.average, "average", { "\(Text.stringFromTime(interval: self.avg))" })
			]
			return jsonDescription(title: "\(name)", items: items, options: config.intervalConfiguration.options)
		}
	}
	
	/// Start a time interval.
	///
	/// A time interval can be created and then used for logging running time statistics.
	///
	/// 	let log = DLog()
	/// 	let interval = log.interval("Sort")
	/// 	interval.begin()
	/// 	...
	/// 	interval.end()
	///
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
	/// 	let log = DLog()
	/// 	let interval = log.interval("Sort")
	/// 	interval.begin()
	/// 	...
	/// 	interval.end()
	///
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
