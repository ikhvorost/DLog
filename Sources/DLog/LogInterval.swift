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


public struct IntervalOptions: OptionSet {
	public let rawValue: Int
	
	public init(rawValue: Int) {
		self.rawValue = rawValue
	}
	
	public static let duration = IntervalOptions(rawValue: 1 << 0)
	public static let count = IntervalOptions(rawValue: 1 << 1)
	public static let total = IntervalOptions(rawValue: 1 << 2)
	public static let min = IntervalOptions(rawValue: 1 << 3)
	public static let max = IntervalOptions(rawValue: 1 << 4)
	public static let average = IntervalOptions(rawValue: 1 << 5)
	
	public static let compact: IntervalOptions = [.duration, .average]
	public static let regular: IntervalOptions = [.duration, .average, .count, .total]
	public static let all: IntervalOptions = [.duration, .count, .total, .min, .max, .average]
}

public struct IntervalConfig {
	public var options: IntervalOptions
	
	public init(options: IntervalOptions = .compact) {
		self.options = options
	}
}

/// An object that represents a time interval triggered by the user.
///
/// Interval logs a point of interest in your code as running time statistics for debugging performance.
///
public class LogInterval : LogItem {
	let id : Int
	let logger: DLog
	let name: StaticString
	@Atomic var begun = false
	let config: IntervalConfig
	
	// SignpostID
	private var _signpostID: Any? = nil
	var signpostID: OSSignpostID? {
		set { _signpostID = newValue }
		get { _signpostID as? OSSignpostID }
	}
	
	/// A number of total calls of a interval
	internal(set) public var count = 0
	
	/// A time duration of a interval
	private(set) public var duration: TimeInterval = 0
	
	/// A total time duration of all calls of a interval
	internal(set) public var total: TimeInterval = 0
	
	/// A minimum time duration of a interval
	internal(set) public var min: TimeInterval = 0
	
	/// A maximum time duration of a interval
	internal(set) public var max: TimeInterval = 0
	
	/// A average time duration of a interval
	internal(set) public var avg: TimeInterval = 0
	
	init(id: Int, logger: DLog, category: String, scope: LogScope?, config: IntervalConfig, file: String, funcName: String, line: UInt, name: StaticString) {
		self.id = id
		self.logger = logger
		self.name = name
		self.config = config
		
		super.init(category: category, scope: scope, type: .interval, file: file, funcName: funcName, line: line, text: { "\(name)" })
	}
	
	func description() -> String {
		
		let items: [(IntervalOptions, String, () -> String)] = [
			(.duration, "duration", { "\(Text.stringFromTime(interval: self.duration))" }),
			(.count, "count", { "\(self.count)" }),
			(.total, "total", { "\(Text.stringFromTime(interval: self.total))" }),
			(.min, "min", { "\(Text.stringFromTime(interval: self.min))" }),
			(.max, "max", { "\(Text.stringFromTime(interval: self.max))" }),
			(.average, "average", { "\(Text.stringFromTime(interval: self.avg))" }),
		]
		
		return jsonDescription(title: "\(name)", items: items, options: config.options)
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
		
		logger.end(interval: self)
	}
}
