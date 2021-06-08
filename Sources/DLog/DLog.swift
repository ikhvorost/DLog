//
//  DLog.swift
//
//  Created by Iurii Khvorost <iurii.khvorost@gmail.com> on 2020/06/03.
//  Copyright © 2020 Iurii Khvorost. All rights reserved.
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

fileprivate class IntervalData {
	var count = 0
	var total: TimeInterval = 0
	var min: TimeInterval = 0
	var max: TimeInterval = 0
	var avg: TimeInterval = 0
}

public struct LogOptions: OptionSet {
	public let rawValue: Int
	
	public init(rawValue: Int) {
		self.rawValue = rawValue
	}
	
	public static let sign = Self(rawValue: 1 << 0)
	public static let time = Self(rawValue: 1 << 1)
	public static let level = Self(rawValue: 1 << 2)
	public static let category = Self(rawValue: 1 << 3)
	public static let padding = Self(rawValue: 1 << 4)
	public static let type = Self(rawValue: 1 << 5)
	public static let location = Self(rawValue: 1 << 6)
	
	public static let compact: Self = [.sign, .time]
	public static let regular: Self = [.sign, .time, .category, .padding, .type, .location]
	public static let all: Self = [.sign, .time, .level, .category, .padding, .type, .location]
}

public struct LogConfig {
	public var sign: Character = "•"
	public var options: LogOptions = .regular
	
	public var trace = TraceConfig()
	public var interval = IntervalConfig()
	
	public init() {}
}

/// The central class to emit log messages to specified outputs using one of the methods corresponding to a log level.
///
public class DLog: LogProtocol {
	
	private let output: LogOutput?
	let config: LogConfig

	@Atomic private var scopes = [LogScope]()
	@Atomic private var intervals = [Int : IntervalData]()
	
	/// The shared disabled log.
	///
	/// Using this constant prevents from logging messages.
	///
	/// 	let log = DLog.disabled
	///
	public static let disabled = DLog(nil)
	
	var disabled : Bool { output == nil }
	
	/// LogProtocol parameters
	public lazy var params = LogParams(logger: self, category: "DLOG", scope: nil)

	/// Creates a logger object that assigns log messages to a specified category.
	///
	/// You can define category name to differentiate unique areas and parts of your app and DLog uses this value
	/// to categorize and filter related log messages.
	///
	/// 	let log = DLog()
	/// 	let netLog = log["NET"]
	/// 	let netLog.log("Hello Net!")
	///
	public subscript(category: String) -> LogCategory {
		LogCategory(logger: self, category: category)
	}

	/// Creates the logger instance with a target output object.
	///
	/// Create an instance and use it to log text messages about your app’s behaviour and to help you assess the state
	/// of your app later. You also can choose a target output and a log level to indicate the severity of that message.
	///
	/// 	let log = DLog()
	///     log.log("Hello DLog!")
	///
	/// - Parameters:
	/// 	- output: A target output object. If it is omitted the logger uses `stdout` by default.
	///
	public init(_ output: LogOutput? = .stdout, config: LogConfig = LogConfig()) {
		self.output = output
		self.config = config
	}

	// Scope

	func enter(scope: LogScope) {
		guard let out = output else { return }

		synchronized(self) {
			let level = scopes.last?.level ?? 0
			scope.level = level + 1
			scopes.append(scope)

			out.scopeEnter(scope: scope, scopes: scopes)
		}
	}

	func leave(scope: LogScope) {
		guard let out = output else { return }

		synchronized(self) {
			if scopes.contains(where: { $0.uid == scope.uid }) {
				out.scopeLeave(scope: scope, scopes: scopes)

				scopes.removeAll { $0.uid == scope.uid }
			}
		}
	}

	// Interval
	
	private func intervalData(id: Int) -> IntervalData {
		if let data = intervals[id] {
			return data
		}
		
		let data = IntervalData()
		intervals[id] = data
		return data
	}

	func begin(interval: LogInterval) {
		guard let out = output else { return }

		out.intervalBegin(interval: interval)
	}

	func end(interval: LogInterval) {
		guard let out = output else { return }
		
		synchronized(self) {
			let data = intervalData(id: interval.id)
			
			data.count += 1
			data.total += interval.duration
			if data.min == 0 || data.min > interval.duration {
				data.min = interval.duration
			}
			if data.max == 0 || data.max < interval.duration {
				data.max = interval.duration
			}
			data.avg = data.total / Double(data.count)
			
			interval.time = Date()
			interval.count = data.count
			interval.total = data.total
			interval.min = data.min
			interval.max = data.max
			interval.avg = data.avg
			interval.text = { interval.description() }
		}

		out.intervalEnd(interval: interval, scopes: scopes)
	}

	func log(text: @escaping () -> String, type: LogType, category: String, scope: LogScope?, file: String, function: String, line: UInt) -> String? {
		guard let out = output else { return nil }

		let item = LogItem(
			category: category,
			scope: scope,
			type: type,
			file: file,
			funcName: function,
			line: line,
			text: text,
			config: config)
		return out.log(item: item, scopes: scopes)
	}

	func scope(name: String, category: String, file: String, function: String, line: UInt, closure: ((LogScope) -> Void)?) -> LogScope {
		let scope = LogScope(logger: self,
							 category: category,
							 file: file,
							 funcName: function,
							 line: line,
							 name: name,
							 config: config)

		if let block = closure {
			scope.enter()
			block(scope)
			scope.leave()
		}

		return scope
	}

	func interval(name: StaticString, category: String, scope: LogScope?, file: String, function: String, line: UInt, closure: (() -> Void)?) -> LogInterval {
		let id = "\(file):\(line)".hash
		let interval = LogInterval(id: id,
							  logger: self,
							  category: category,
							  scope: scope,
							  file: file,
							  funcName: function,
							  line: line,
							  name: name,
							  config: config)
		
		if let block = closure {
			interval.begin()
			block()
			interval.end()
		}

		return interval
	}
}
