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

extension OptionSet where RawValue == Int {
	/// All available options
	public static var all: Self {
		Self.init(rawValue: Int.max)
	}
	
	init(_ shift: Int) {
		self.init(rawValue: 1 << shift)
	}
}

/// Indicates which info from the logger should be used.
public struct LogOptions: OptionSet {
	/// The corresponding value of the raw type.
	public let rawValue: Int
	
	/// Creates a new option set from the given raw value.
	public init(rawValue: Int) {
		self.rawValue = rawValue
	}
	
	/// Start sign
	public static let sign = Self(0)
	
	/// Timestamp
	public static let time = Self(1)
	
	/// Level of the current scope
	public static let level = Self(2)
	
	/// Category
	public static let category = Self(3)
	
	/// The current scope padding
	public static let padding = Self(4)
	
	/// Log type
	public static let type = Self(5)
	
	/// Location
	public static let location = Self(6)
	
	/// Compact: `.sign` and `.time`
	public static let compact: Self = [.sign, .time]
	
	/// Regular: `.sign`, `.time`, `.category`, `.padding`, `.type` and `.location`
	public static let regular: Self = [.sign, .time, .category, .padding, .type, .location]
}

/// Contains configuration values regarding to the logger
public struct LogConfiguration {
	/// Start sign of the logger
	public var sign: Character = "•"
	
	/// Set which info from the logger should be used. Default value is `LogOptions.regular`.
	public var options: LogOptions = .regular
	
	/// Configuration of the `trace` method
	public var traceConfiguration = TraceConfiguration()
	
	/// Configuration of intervals
	public var intervalConfiguration = IntervalConfiguration()
	
	/// Creates the logger's default configuration.
	public init() {}
}

/// The central class to emit log messages to specified outputs using one of the methods corresponding to a log level.
///
public class DLog: NSObject, LogProtocol {
	
	private let output: LogOutput?
	let config: LogConfiguration

	@Atomic private var scopes = [LogScope]()
	
	/// The shared disabled log.
	///
	/// Using this constant prevents from logging messages.
	///
	/// 	let log = DLog.disabled
	///
	@objc
	public static let disabled = DLog(nil)
	
	/// The default configuration.
	public static let defaultConfiguration = LogConfiguration()
	
	var disabled : Bool { output == nil }
	
	/// Creates a logger object that assigns log messages to a specified category.
	///
	/// You can define category name to differentiate unique areas and parts of your app and DLog uses this value
	/// to categorize and filter related log messages.
	///
	/// 	let log = DLog()
	/// 	let netLog = log["NET"]
	/// 	let netLog.log("Hello Net!")
	///
	@objc
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
	public init(_ output: LogOutput? = .stdout, configuration: LogConfiguration = DLog.defaultConfiguration) {
		self.output = output
		self.config = configuration
	}
	
	@objc
	override public init() {
		self.output = .stdout
		self.config = DLog.defaultConfiguration
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
	
	func begin(interval: LogInterval) {
		guard let out = output else { return }

		out.intervalBegin(interval: interval)
	}

	func end(interval: LogInterval) {
		guard let out = output else { return }

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

	func interval(name: String? = nil, staticName: StaticString? = nil, category: String, scope: LogScope?, file: String, function: String, line: UInt, closure: (() -> Void)?) -> LogInterval {
		let interval = LogInterval(logger: self,
							  category: category,
							  scope: scope,
							  name: name,
							  staticName: staticName,
							  file: file,
							  funcName: function,
							  line: line,
							  config: config)
		
		if let block = closure {
			interval.begin()
			block()
			interval.end()
		}

		return interval
	}
	
	// MARK: - LogProtocol
	
	/// LogProtocol parameters
	public lazy var params = LogParams(logger: self, category: "DLOG", scope: nil)

	@objc
	public lazy var log: LogClosure = { (text, file, function, line) in
		(self as LogProtocol).log(text, file: file, function: function, line: line)
	}
	
	@objc
	public lazy var trace: TraceClosure = { (text, file, function, line, addresses) in
		(self as LogProtocol).trace(text, file: file, function: function, line: line, addresses: addresses)
	}
	
	@objc
	public lazy var debug: LogClosure = { (text, file, function, line) in
		(self as LogProtocol).debug(text, file: file, function: function, line: line)
	}
	
	@objc
	public lazy var info: LogClosure = { (text, file, function, line) in
		(self as LogProtocol).info(text, file: file, function: function, line: line)
	}
	
	@objc
	public lazy var warning: LogClosure = { (text, file, function, line) in
		(self as LogProtocol).warning(text, file: file, function: function, line: line)
	}
	
	@objc
	public lazy var error: LogClosure = { (text, file, function, line) in
		(self as LogProtocol).error(text, file: file, function: function, line: line)
	}
	
	@objc
	public lazy var assert: AssertClosure = { (condition, text, file, function, line) in
		(self as LogProtocol).assert(condition, text, file: file, function: function, line: line)
	}
	
	@objc
	public lazy var fault: LogClosure = { (text, file, function, line) in
		(self as LogProtocol).fault(text, file: file, function: function, line: line)
	}
	
	@objc
	public lazy var scope: ScopeClosure = { (name, file, function, line, closure) in
		(self as LogProtocol).scope(name, file: file, function: function, line: line, closure: closure)
	}
	
	@objc
	public lazy var interval: IntervalClosure = { (name, file, function, line, closure) in
		(self as LogProtocol).interval(name: name, file: file, function: function, line: line, closure: closure)
	}
}
