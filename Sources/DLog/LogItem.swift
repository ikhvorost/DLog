//
//  LogItem.swift
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
import os.log


/// Logging levels supported by the logger.
///
/// A log type controls the conditions under which a message should be logged.
///
public enum LogType : Int {
	/// The default log level to capture non critical information.
	case log
	
	/// The informational log level to capture information messages and helpful data.
	case info
	
	/// The trace log level to capture the current function name to help in debugging problems during the development.
	case trace
	
	/// The debug log level to capture information that may be useful during development or while troubleshooting a specific problem.
	case debug
	
	/// The warning log level to capture information about things that might result in an error.
	case warning
	
	/// The error log level to report errors.
	case error
	
	/// The assert log level for sanity checks.
	case assert
	
	/// The fault log level to capture system-level or multi-process information when reporting system errors.
	case fault
	
	/// The interval log level.
	case interval
	
	/// The scope log level.
	case scope
}

/// A base log message class that the logger adds to the logs.
///
/// It contains all available properties of the log message.
///
public class LogItem {
	/// The timestamp of this log message.
	internal(set) public var time = Date()
	
	/// The category of this log message.
	public let category: String
	
	/// The scope of this log message.
	public let scope: LogScope?
	
	/// The log level of this log message.
	public let type: LogType
	
	/// The file name this log message originates from.
	public let fileName: String
	
	/// The function name this log message originates from.
	public let funcName: String
	
	/// The line number of code this log message originates from.
	public let line: UInt
	
	/// The text of this log message.
	private let _text: (() -> String)!
	
	public func text() -> String {
		precondition(_text != nil, "Text is empty.")
		return _text()
	}
	
	let config: LogConfig

	init(category: String, scope: LogScope?, type: LogType, file: String, funcName: String, line: UInt, text: (() -> String)!, config: LogConfig) {
		self.category = category
		self.scope = scope
		self.type = type
		self.fileName = ((file as NSString).lastPathComponent as NSString).deletingPathExtension
		self.funcName = funcName
		self.line = line
		self._text = text
		self.config = config
	}
}

/// An object that represents a scope triggered by the user.
///
/// Scope provides a mechanism for grouping log messages.
///
public class LogScope : LogItem, LogProtocol {
	let logger: DLog
	let uid = UUID()
	var os_state = os_activity_scope_state_s()
	@Atomic var entered = false
	
	/// LogProtocol parameters
	public lazy var params = LogParams(logger: logger, category: category, scope: self)
	
	/// A global level of a scope
	internal(set) public var level: Int = 0
	
	/// A time duration of a scope
	private(set) public var duration: TimeInterval = 0
	
	init(logger: DLog, category: String, file: String, funcName: String, line: UInt, name:  @autoclosure @escaping () -> String, config: LogConfig) {
		self.logger = logger
		super.init(category: category, scope: nil, type: .scope, file: file, funcName: funcName, line: line, text: name, config: config)
	}
	
	/// Start a scope.
	///
	/// A scope can be created and then used for logging grouped log messages.
	///
	/// 	let log = DLog()
	/// 	let scope = log.scope("Auth")
	/// 	scope.enter()
	///
	/// 	scope.log("message")
	/// 	...
	///
	/// 	scope.leave()
	///
	public func enter() {
		guard !entered else { return }
		entered.toggle()
		
		time = Date()
		duration = 0
		logger.enter(scope: self)
	}
	
	/// Finish a scope.
	///
	/// A scope can be created and then used for logging grouped log messages.
	///
	/// 	let log = DLog()
	/// 	let scope = log.scope("Auth")
	/// 	scope.enter()
	///
	/// 	scope.log("message")
	/// 	...
	///
	/// 	scope.leave()
	///
	public func leave() {
		guard entered else { return }
		entered.toggle()
		
		duration = -time.timeIntervalSinceNow
		
		logger.leave(scope: self)
	}
}
