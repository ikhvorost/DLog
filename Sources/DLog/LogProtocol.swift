//
//  LogProtocol.swift
//
//  Created by Iurii Khvorost <iurii.khvorost@gmail.com> on 2020/10/14.
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

/// LogProtocol parameters
///
public struct LogParams {
	let logger: DLog
	let category: String
	let scope: LogScope?
}

/// Base logger protocol
///
public protocol LogProtocol {
	/// LogProtocol parameters
	var params: LogParams { get }
}

extension LogProtocol {
	
	/// Logs a message that is essential to troubleshoot problems later.
	///
	/// This method logs the message using the default log level.
	///
	///		let log = DLog()
	///		log.log("message")
	///
	/// - Parameters:
	/// 	- text: The message to be logged that can be used with any string interpolation literal.
	/// 	- file: The file this log message originates from (defaults to `#file`).
	/// 	- function: The function this log message originates from (defaults to `#function`).
	/// 	- line: The line this log message originates (defaults to `#line`).
	///
	/// - Returns: Returns an optional string value indicating whether a log message is generated and processed.
	///
	@discardableResult
	public func log(_ text: String, file: String = #file, function: String = #function, line: UInt = #line) -> String? {
		params.logger.log(text: text, type: .log, category: params.category, scope: params.scope, file: file, function: function, line: line)
	}
	
	/// Logs trace information to help debug problems during the development of your code.
	///
	/// Use it during development to record information that might aid you in debugging problems later.
	///
	///		let log = DLog()
	///		log.trace("message")
	///
	/// - Parameters:
	/// 	- text: The message to be logged that can be used with any string interpolation literal.
	/// 	- file: The file this log message originates from (defaults to `#file`).
	/// 	- function: The function this log message originates from (defaults to `#function`).
	/// 	- line: The line this log message originates (defaults to `#line`).
	///
	/// - Returns: Returns an optional string value indicating whether a log message is generated and processed.
	///
	@discardableResult
	public func trace(_ text: String? = nil, file: String = #file, function: String = #function, line: UInt = #line) -> String? {
		let msg = "\(function) \(text ?? "")"
		return params.logger.log(text: msg, type: .trace, category: params.category, scope: params.scope, file: file, function: function, line: line)
	}
	
	/// Logs a message to help debug problems during the development of your code.
	///
	/// Use this method during development to record information that might aid you in debugging problems later.
	///
	///		let log = DLog()
	///		log.debug("message")
	///
	/// - Parameters:
	/// 	- text: The message to be logged that can be used with any string interpolation literal.
	/// 	- file: The file this log message originates from (defaults to `#file`).
	/// 	- function: The function this log message originates from (defaults to `#function`).
	/// 	- line: The line this log message originates (defaults to `#line`).
	///
	/// - Returns: Returns an optional string value indicating whether a log message is generated and processed.
	///
	@discardableResult
	public func debug(_ text: String, file: String = #file, function: String = #function, line: UInt = #line) -> String? {
		params.logger.log(text: text, type: .debug, category: params.category, scope: params.scope, file: file, function: function, line: line)
	}
	
	/// Logs a message that is helpful, but not essential, to diagnose issues with your code.
	///
	/// Use this method to capture information messages and helpful data.
	///
	///		let log = DLog()
	///		log.info("message")
	///
	/// - Parameters:
	/// 	- text: The message to be logged that can be used with any string interpolation literal.
	/// 	- file: The file this log message originates from (defaults to `#file`).
	/// 	- function: The function this log message originates from (defaults to `#function`).
	/// 	- line: The line this log message originates (defaults to `#line`).
	///
	/// - Returns: Returns an optional string value indicating whether a log message is generated and processed.
	///
	@discardableResult
	public func info(_ text: String, file: String = #file, function: String = #function, line: UInt = #line) -> String? {
		params.logger.log(text: text, type: .info, category: params.category, scope: params.scope, file: file, function: function, line: line)
	}
	
	/// Logs a warning that occurred during the execution of your code.
	///
	/// Use this method to capture information about things that might result in an error.
	///
	///		let log = DLog()
	///		log.warning("message")
	///
	/// - Parameters:
	/// 	- text: The message to be logged that can be used with any string interpolation literal.
	/// 	- file: The file this log message originates from (defaults to `#file`).
	/// 	- function: The function this log message originates from (defaults to `#function`).
	/// 	- line: The line this log message originates (defaults to `#line`).
	///
	/// - Returns: Returns an optional string value indicating whether a log message is generated and processed.
	///
	@discardableResult
	public func warning(_ text: String, file: String = #file, function: String = #function, line: UInt = #line) -> String? {
		params.logger.log(text: text, type: .warning, category: params.category, scope: params.scope, file: file, function: function, line: line)
	}
	
	/// Logs an error that occurred during the execution of your code.
	///
	/// Use this method to report errors.
	///
	///		let log = DLog()
	///		log.error("message")
	///
	/// - Parameters:
	/// 	- text: The message to be logged that can be used with any string interpolation literal.
	/// 	- file: The file this log message originates from (defaults to `#file`).
	/// 	- function: The function this log message originates from (defaults to `#function`).
	/// 	- line: The line this log message originates (defaults to `#line`).
	///
	/// - Returns: Returns an optional string value indicating whether a log message is generated and processed.
	///
	@discardableResult
	public func error(_ text: String, file: String = #file, function: String = #function, line: UInt = #line) -> String? {
		params.logger.log(text: text, type: .error, category: params.category, scope: params.scope, file: file, function: function, line: line)
	}
	
	/// Logs a traditional C-style assert notice with an optional message.
	///
	/// Use this function for internal sanity checks.
	///
	///		let log = DLog()
	///		log.assert(condition, "message")
	///
	/// - Parameters:
	/// 	- condition: The condition to test.
	/// 	- text: A string to print if `condition` is evaluated to `false`. The default is an empty string.
	/// 	- file: The file this log message originates from (defaults to `#file`).
	/// 	- function: The function this log message originates from (defaults to `#function`).
	/// 	- line: The line this log message originates (defaults to `#line`).
	///
	/// - Returns: Returns an optional string value indicating whether a log message is generated and processed.
	///
	@discardableResult
	public func assert(_ condition: Bool, _ text: String = "", file: String = #file, function: String = #function, line: UInt = #line) -> String? {
		guard !condition else { return nil }
		return params.logger.log(text: text, type: .assert, category: params.category, scope: params.scope, file: file, function: function, line: line)
	}
	
	/// Logs a bug or fault that occurred during the execution of your code.
	///
	/// Use this method to capture critical errors that occurred during the execution of your code.
	///
	///		let log = DLog()
	///		log.fault("message")
	///
	/// - Parameters:
	/// 	- text: The message to be logged that can be used with any string interpolation literal.
	/// 	- file: The file this log message originates from (defaults to `#file`).
	/// 	- function: The function this log message originates from (defaults to `#function`).
	/// 	- line: The line this log message originates (defaults to `#line`).
	///
	/// - Returns: Returns an optional string value indicating whether a log message is generated and processed.
	///
	@discardableResult
	public func fault(_ text: String, file: String = #file, function: String = #function, line: UInt = #line) -> String? {
		params.logger.log(text: text, type: .fault, category: params.category, scope: params.scope, file: file, function: function, line: line)
	}
	
	/// Creates a scope object that can assign log messages to itself.
	///
	/// Scope provides a mechanism for grouping log messages in your program.
	///
	///		let log = DLog()
	///		log.scope("Auth") { scope in
	///			scope.log("message")
	///		}
	///
	/// - Parameters:
	/// 	- name: The name of new scope object.
	/// 	- file: The file this log message originates from (defaults to `#file`).
	/// 	- function: The function this log message originates from (defaults to `#function`).
	/// 	- line: The line this log message originates (defaults to `#line`).
	/// 	- closure: A closure to be executed with the scope. The block takes a single `LogScope` parameter and has no return value.
	///
	/// - Returns: An `LogScope` object for the new scope.
	///
	@discardableResult
	public func scope(_ name: String, file: String = #file, function: String = #function, line: UInt = #line, closure: ((LogScope) -> Void)? = nil) -> LogScope {
		params.logger.scope(name: name, category: params.category, file: file, function: function, line: line, closure: closure)
	}
	
	/// Creates an interval object that logs a detailed message with accumulated statistics.
	///
	/// Logs a point of interest in your code as time intervals for debugging performances.
	///
	///		let log = DLog()
	///		log.interval("Sorting") {
	///			...
	///		}
	///
	/// - Parameters:
	/// 	- name: The name of new interval object.
	/// 	- file: The file this log message originates from (defaults to `#file`).
	/// 	- function: The function this log message originates from (defaults to `#function`).
	/// 	- line: The line this log message originates (defaults to `#line`).
	/// 	- closure: A closure to be executed with the interval.
	///
	/// - Returns: An `LogInterval` object for the new interval.
	///
	@discardableResult
	public func interval(_ name: StaticString, file: String = #file, function: String = #function, line: UInt = #line, closure: (() -> Void)? = nil) -> LogInterval {
		params.logger.interval(name: name, category: params.category, scope: params.scope, file: file, function: function, line: line, closure: closure)
	}
}
